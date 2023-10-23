#############################################
# Description: 
# This script pulls M365 app usage data from MSGraph and outputs a CSV file with the following data:
# - User Principal Name
# - WindowsUser (If the user has acced M365 from a Windows device)
# - MacUser (If the user has acced M365 from a Mac device)
# - MobileUser (If the user has acced M365 from a Mobile device)
# - WebUser (If the user has acced M365 from a Web browser)
# - OutlookUsageDays (Number of days Outlook was used)
# - WordUsageDays (Number of days Word was used)
# - ExcelUsageDays (Number of days Excel was used)
# - PowerPointUsageDays (Number of days PowerPoint was used)
# - TeamsUsageDays (Number of days Teams was used)
# - OneNoteUsageDays (Number of days OneNote was used)
# - DaysOfData (Total number of days of data for the user (will be less than the days to go back if the user was not active in the period))
# - TotalDaysOfData (Total number of days of data in the complete data set)
# - LicensedForCopilot (If the users license is cable of adding Copilot e.g. E3 / E5)
# - EmailsSentInPeriod (Number of emails sent in the period)
# - ActiveFilesInSPOInPeriod (Number of active files in SPO in the period)
# - ActiveFilesInOneDriveInPeriod (Number of active files in OneDrive in the period)
# - TotalAudioTimeMins(Total Aduio time of meetings in teams)
# - DeepAnalysisPeriod (Period the data was collected for e.g. D30)
#
# This report can be used to understand heavy users of M365. Aka good candidates for Copilot.
#
# This script will run but will not be able to tie up usage to user if masking is enabled
#              
# Todo:
# - Add support for users MSSearch queries (may not be possible) [Content Search]
#
#
# Alex Grover - alexgrover@microsoft.com
#
# VersionLog : 
# 2023-09-27 - Initial version
# 2023-10-03 - Fixed bug in returning user platform usage
# 2023-10-03 - Added deeper analysis options for Emails Sent and Active Files in OneDrive
# 2023-10-16 - Removed need to load each user to check license, this is done with another report
# 2023-10-17 - Flushing the output to avoid memory expections for large tenants, added grouping to help with memory exceptions
# 2023-10-23 - Updated data collection method to pull data for previously collected days which are empty, added DaysOfData value to output, added total aduio time for team calls
#
##############################################
# Dependencies
##############################################
## Requires the following modules:
try {
    Import-Module Microsoft.Graph.Reports
}
catch {
    Write-Error "Error importing modules required modules - $($Error[0].Exception.Message))"
    Exit
}

# Graph Permissions
# Reports.Read.All


##############################################
# Variables
##############################################

# Auth
$delegatedAuth = $false                 # If true, delegated auth will be used. If false, app only auth will be used

$clientId = "38acafba-2eb6-4510-848e-070b493ea4dc"
$tenantId = "groverale.onmicrosoft.com"
$thumbprint = "72A385EF67B35E1DFBACA89180B7B3C8F97453D7"

# Log file location (timestamped with script start time)
$timeStamp = Get-Date -Format "yyyyMMddHHmmss"
$reportFileLocation = "Output\M365AppUsageReportTotals-$timeStamp.csv"
$dataFolder = "Data\"

# Days to go back (max is 28)
$daysToGoBack = 28

# Users to check config
$checkAllUsers = $false                 # If true, all users in the tenant will be checked
$checkAllLicensedUsers = $true         # If true, only users with licenses in the $licenseSKUs array will be checked
$usersToCheckPath = "UsersToCheck.txt"  # If not checking all users / all licensed users, this file will be used to get the list of users to check

# Licenses to check
$productSKUs = @(
    "MICROSOFT 365 E3"          # "6fd2c87f-b296-42f0-b197-1e91e994b900", # Microsoft 365 E3
    "MICROSOFT 365 E5"          # "c7df2760-2c81-4ef7-b578-5b5392b571df", # Microsoft 365 E5
    "OFFICE 365 E3 DEVELOPER"   # "189a915c-fe4f-4ffa-bde4-85b9628d07a0"  # DeveloperPack (Gives E3 license)
)

# Deeper Analysis
$deepAnalysis = $true                    # If true, deeper analysis will be done (Email, OneDrive)
$period = "D90"                          # Period to get data for (D7 = 7 days, D30 = 30 days, D90 = 90 days, D180 = 180 days)

##############################################
# Functions
##############################################

function ConnectToMSGraph 
{  
    try{
        # Disconnect if already connected
        #Disconnect-MgGraph

        if($delegatedAuth) {
            Connect-MgGraph -Scopes Reports.Read.All, User.Read.All -ErrorAction Stop
            return
        }

        Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $thumbprint -ErrorAction Stop
    }
    catch{
        Write-Host "Error connecting to MS Graph - $($Error[0].Exception.Message)" -ForegroundColor Red
        Exit
    }
}

function Get-AppUserDetailsForDate($date) {

    try {
        $dateString = $date.ToString("yyyy-MM-dd")
        $outputPath = Join-Path -Path $dataFolder -ChildPath "M365AppUserReport-$dateString.csv"
        Get-MgReportM365AppUserDetail -Date $date -OutFile $outputPath
        return $true
    }
    catch {
        Write-Error "Error getting app user details for date $date - $($_.Exception.Message)"
        return $false
    }
}

function Get-UserDetail() {
    try {
        $today = Get-Date
        $dateString = $today.ToString("yyyy-MM-dd")
        $outputPath = Join-Path -Path $dataFolder -ChildPath "M365UserDetailReport-$dateString.csv"
        # Check if we already have the data for this date
        $userData = Get-ChildItem -Path $dataFolder -Filter "M365UserDetailReport-$dateString.csv"
        if($userData) {
            Write-Host "Data already exists for date $today"
            return Import-Csv -Path $outputPath
        }
        Get-MgReportOffice365ActiveUserDetail -Period D7 -OutFile $outputPath
        ## Import data and return
        return Import-Csv -Path $outputPath
    }
    catch {
        Write-Error "Error getting user details for date $date - $($_.Exception.Message)"
        return $false
    }
    
}

function Get-GetExchangeData($date) {

    try {
        $dateString = $date.ToString("yyyy-MM-dd")
        $outputPath = Join-Path -Path $dataFolder -ChildPath "ExchangeUserReport-$dateString.csv"
        Get-MgReportM365AppUserDetail -Date $date -OutFile $outputPath
        return $true
    }
    catch {
        Write-Error "Error getting app user details for date $date - $($_.Exception.Message)"
        return $false
    }
}

function CombineAndTransformData {
    $combinedData = @()
    $files = Get-ChildItem -Path $dataFolder -Filter M365AppUserReport*.csv
    foreach($file in $files) {
        $data = Import-Csv -Path $file.FullName
        $combinedData += $data
    }

    return $combinedData
}

function PullAppUsageData {
    for($i = 0; $i -lt $daysToGoBack; $i++) {
        $today = Get-Date
        $date = $today.AddDays(-$i)
        
        # Check if we already have the data for this date
        $appData = Get-ChildItem -Path $dataFolder -Filter "M365AppUserReport-$($date.ToString("yyyy-MM-dd")).csv"
        if($appData) {

            ## Get first two lines of the file
            $firstTwoLines = Get-Content -Path $appData.FullName -TotalCount 2
            if ($firstTwoLines.Length -eq 2) {
                Write-Host "Data already exists for date $date"
                continue
            }

            ## If length is not two then we have one line that is the header. So overwrite the file as empty
        }
    
        Write-Host "Getting app user details for date $date"
        Get-AppUserDetailsForDate($date)
    }
}

function PullEmailUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "ExchangeUserReport-$($today.ToString("yyyy-MM-dd"))-$period.csv"
    
    try {
        $existingReport = Get-ChildItem -Path $outputPath -ErrorAction Stop
        if ($existingReport) {
            return Import-Csv $outputPath  
        }
    } catch {
        Get-MgReportEmailActivityUserDetail -Period $period -OutFile $outputPath
        return Import-Csv $outputPath
    }
    
}

function PullOneDriveUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "OneDriveActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"
    
    try {
        $existingReport = Get-ChildItem -Path $outputPath -ErrorAction Stop
        if ($existingReport) {
            return Import-Csv $outputPath  
        }
    }
    catch { 
        #Get-MgReportOneDriveUsageAccountDetail -Period $period -OutFile $outputPath
        Get-MgReportOneDriveActivityUserDetail -Period $period -OutFile $outputPath
        return Import-Csv $outputPath
    }  
}

function PullSPOUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "SharePointActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"

    try {
        $existingReport = Get-ChildItem -Path $outputPath -ErrorAction Stop
        if ($existingReport) {
            return Import-Csv $outputPath  
        }
    } catch {
        #Get-MgReportSharePointSiteUsageDetail -Period $period -OutFile $outputPath
        Get-MgReportSharePointActivityUserDetail -Period $period -OutFile $outputPath
        return Import-Csv $outputPath
    }
}

function PullTeamUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "TeamActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"

    try {
        $existingReport = Get-ChildItem -Path $outputPath -ErrorAction Stop
        if ($existingReport) {
            return Import-Csv $outputPath  
        }
    } catch {
        Get-MgReportTeamUserActivityUserDetail -Period $period -OutFile $outputPath
        return Import-Csv $outputPath
    }
}

function GetUsersToCheck ($userDetailsReportGraphData) {

    $users = @()

    if ($checkAllUsers) {
        ## v1.0 method of getting users
        #return Get-MgUser -All -Property UserPrincipalName, Id

        ## v1.1 method of getting users
        $users = $userDetailsReportGraphData | Select -Property "User Principal Name", "Assigned Products"
        return $users
    }

    if ($checkAllLicensedUsers) {
        # $allUsers = Get-MgUser -All -Property UserPrincipalName, Id
        # foreach($user in $allUsers) {
        #     if (IsUserLicensedForCopilot -userId $user.Id)
        #     {
        #         $users += $user
        #     }
        # }
        # return $users

        ## v1.1 method of getting users
        return $userDetailsReportGraphData | where { IsUserLicensedForCopilot2 -userFromGraphReport $_ } | Select -Property "User Principal Name", "Assigned Products"
    }
    
    if (-not (Test-Path -Path $usersToCheckPath)) {
        Write-Error "UsersToCheck file not found"
        Exit
    }

    $usersToCheck = Get-Content -Path $usersToCheckPath
    foreach($user in $usersToCheck) {
        $user = $user.Trim()
        $user = $userDetailsReportGraphData | where { $_.'User Principal Name' -eq $user } | Select -Property "User Principal Name", "Assigned Products"
        if($user) {
            $users += $user
        }
    }

    return $users
}

function IsUserLicensedForCopilot($userId) {
    $licenses = Get-MgUserLicenseDetail -UserId $userId
    foreach($license in $licenses) {
        if($licenseSKUs.Contains($license.SkuId)) {
            return $true
        }
    }

    return $false
}

function IsUserLicensedForCopilot2($userFromGraphReport) {
    
    # Sameple produc string 'POWER VIRTUAL AGENTS VIRAL TRIAL+OFFICE 365 E3 DEVELOPER+MICROSOFT POWER APPS PLAN 2 TRIAL+MICROSOFT FABRIC (FREE)'
    # Each produc string is seperated by a '+'
    $products = ($userFromGraphReport.'Assigned Products').Split('+')

    foreach($product in $products) {
        if($productSKUs.Contains($product)) {
            return $true
        }
    }

    return $false
}

function GetUsersTotalAppUsage($userAppData, $upn) {
    $usersTotalAppUsage = New-Object -TypeName PSObject -Property @{
        "User Principal Name" = $upn
    }

    ## If we get a single day where the user has used the app from a platform, 
    ## we will assume they are a user of that platform
    $windowsUser = ($userAppData | where { $_.Windows -eq "Yes" }).Length -gt 0
    $macUser = ($userAppData | where { $_.Mac -eq "Yes" }).Length -gt 0
    $mobileUser = ($userAppData | where { $_.Mobile -eq "Yes" }).Length -gt 0
    $webUser = ($userAppData | where { $_.Web -eq "Yes" }).Length -gt 0

    ## Add platform usage

    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "WindowsUser" -Value $windowsUser
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "MacUser" -Value $macUser
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "MobileUser" -Value $mobileUser
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "WebUser" -Value $webUser

    ## Daily app counts
    $outlookDailyUsageCount = 0
    $wordDailyUsageCount = 0
    $excelDailyUsageCount = 0
    $powerpointDailyUsageCount = 0
    $teamsDailyUsageCount = 0
    $onenoteDailyUsageCount = 0

    $daysOfData = $userAppData.Count

    ## Go through each day and count the app usage
    foreach($day in $userAppData) {

        if ($day.Outlook -eq "Yes") {
            $outlookDailyUsageCount++
        }

        if ($day.Word -eq "Yes") {
            $wordDailyUsageCount++
        }

        if ($day.Excel -eq "Yes") {
            $excelDailyUsageCount++
        }

        if ($day.PowerPoint -eq "Yes") {
            $powerpointDailyUsageCount++
        }

        if ($day.Teams -eq "Yes") {
            $teamsDailyUsageCount++
        }

        if ($day.OneNote -eq "Yes") {
            $onenoteDailyUsageCount++
        }
    }

    ## Add daily app counts
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "OutlookUsageDays" -Value $outlookDailyUsageCount
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "WordUsageDays" -Value $wordDailyUsageCount
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "ExcelUsageDays" -Value $excelDailyUsageCount
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "PowerPointUsageDays" -Value $powerpointDailyUsageCount
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "TeamsUsageDays" -Value $teamsDailyUsageCount
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "OneNoteUsageDays" -Value $onenoteDailyUsageCount

    ## Add total days of data for that user
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "DaysOfData" -Value $daysOfData
    
    return $usersTotalAppUsage
}

function GetValueFromDataForUser($data, $upn, $property, $searchProperty = "User Principal Name") {
    if ($upn -eq "alex@groverale.onmicrosoft.com")
    {
        Write-Host "Getting value for $property for $upn"
    }
    $usersData = $data | where { $_.$searchProperty -eq $upn }
    if ($null -eq $usersData.$property) {
        return 0
    }
    return $usersData.$property
}

##############################################
# Main
##############################################

## Initilaise the stopwatch
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()


ConnectToMSGraph

PullAppUsageData

if ($deepAnalysis)
{
    $emailData = PullEmailUsageData -period $period

    $oneDriveData = PullOneDriveUsageData -period $period
    
    $spoData = PullSPOUsageData -period $period

    $teamData = PullTeamUsageData -period $period
}

$userDetailsReportGraphData = Get-UserDetail

if ($userDetailsReportGraphData -eq $false) {
    Write-Error "Error getting user details report data"
    Exit
}

$users = GetUsersToCheck -userDetailsReportGraphData $userDetailsReportGraphData

## Now the data part
$combinedData = CombineAndTransformData

# Get Total days were of data
$files = Get-ChildItem -Path $dataFolder -Filter M365AppUserReport*.csv
$totalDaysOfData = $files.Count

## Go through each user and filter the data by user
$allUsersTotalAppUsage = @()

## Initilaise the CSV
$allUsersTotalAppUsage | Export-Csv -Path $reportFileLocation -NoTypeInformation -Force

# Grouping by user principal name - memory intensive
Write-Host "Grouping data by user principal name... please wait"
$allUsersAppData = $combinedData | Group-Object -Property 'User Principal Name'
#$allUsersAppData
Write-Host "Finished grouping"

# Initilaise progress bar
#cls
$currentItem = 0
$percent = 0
Write-Progress -Activity "Processing User $currentItem / $($users.Count)" -Status "$percent% Complete:" -PercentComplete $percent

foreach($user in $users) {

    $userAppData = ($allUsersAppData | where { $_.Name -eq $user.'User Principal Name' }).Group

    ## Go through each day record and check if the user has used the app
    $usersTotalAppUsage = GetUsersTotalAppUsage -userAppData $userAppData -upn $user.'User Principal Name'

    ## Add total days of data
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "TotalDaysOfData" -Value $totalDaysOfData

    ## Is the user licensed for copilot
    $licened = IsUserLicensedForCopilot2 -userFromGraphReport $user
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "LicensedForCopilot" -Value $licened

    if ($deepAnalysis)
    {
        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "DeepAnalysisPeriod" -Value $period

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "EmailsSentInPeriod" -Value (GetValueFromDataForUser -data $emailData -upn $user.'User Principal Name' -property 'Send Count')

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "ActiveFilesInOneDriveInPeriod" -Value (GetValueFromDataForUser -data $oneDriveData -upn $user.'User Principal Name' -property 'Viewed Or Edited File Count')

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "ActiveFilesInSPOInPeriod" -Value (GetValueFromDataForUser -data $spoData -upn $user.'User Principal Name' -property 'Viewed Or Edited File Count')

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "TotalAudioTimeMins" -Value ([Math]::Round((GetValueFromDataForUser -data $teamData -upn $user.'User Principal Name' -property 'Audio Duration In Seconds') / 60))
    }

    $usersTotalAppUsage | Export-Csv -Path $reportFileLocation -NoTypeInformation -Append

    ## Update progress bar
    $currentItem++
    $percent = [Math]::Round(($currentItem / $users.Count) * 100)
    Write-Progress -Activity "Processed User $currentItem / $($users.Count)" -Status "$percent% Complete:" -PercentComplete $percent

}

Write-Output "Done: $($stopWatch.Elapsed.ToString())"