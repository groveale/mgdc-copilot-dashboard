#############################################
# Description: 
# This script pulls M365 app usage data from MSGraph and saves the output into an SPO library.
# This data can then be ingested into a data warehouse for further analysis.
#
# Alex Grover - alexgrover@microsoft.com
#
# VersionLog : 
# 2024-01-31 - Initial version
# 2024-02-05 - Added processing using hashtables
#
##############################################
# Dependencies
##############################################
## Requires the following modules:
try {
    Import-Module Microsoft.Graph.Beta.Reports
    Import-Module Microsoft.Graph.Reports
    Import-Module Microsoft.Graph.Sites
}
catch {
    Write-Error "Error importing modules required modules - $($Error[0].Exception.Message))"
    Exit
}

# Graph Permissions
# Reports.Read.All
# ReportSettings.ReadWrite.All
# Sites.Selected


##############################################
# Variables
##############################################

$clientId = "4b7482f3-5fac-470b-8f6a-69b59c87c59f"
$tenantId = "groverale.onmicrosoft.com"
$thumbprint = "BD4D7AC2DBCD010E04194D467AC996F486512A49"

# Log file location (timestamped with script start time)
$timeStamp = Get-Date -Format "yyyyMMddHHmmss"
$reportFileLocation = "Output\M365AppUsageReportTotals-$timeStamp.csv"

#$usageSPOSiteUrl = "https://groverale.sharepoint.com/sites/M365UsageData"
$m365UsageDataSiteId = "7a838fca-e704-4c57-a6a8-a73a8029bca2"
$appUsageProcessedLibraryName = "M365AppUsageProcessedReports"

# Users to check config
$checkAllUsers = $true                 # If true, all users in the tenant will be checked
$checkAllLicensedUsers = $true         # If true, only users with licenses in the $licenseSKUs array will be checked
$usersToCheckPath = "UsersToCheck.txt"  # If not checking all users / all licensed users, this file will be used to get the list of users to check

# Licenses to check
$productSKUs = @(
    "MICROSOFT 365 E3"          # "6fd2c87f-b296-42f0-b197-1e91e994b900", # Microsoft 365 E3
    "MICROSOFT 365 E5"          # "c7df2760-2c81-4ef7-b578-5b5392b571df", # Microsoft 365 E5
    "OFFICE 365 E3 DEVELOPER"   # "189a915c-fe4f-4ffa-bde4-85b9628d07a0"  # DeveloperPack (Gives E3 license)
)

# Data folder
$dataFolder = "C:\Users\alexgrover\source\repos\mgdc-copilot-dashboard\GeneratedData\10K"

# Days to go back (max is 26)
# We have to skip today and yesterday as the data is not available for these days
$daysToGoBack = 26

# Deeper Analysis
$deepAnalysis = $false                    # If true, deeper analysis will be done (Email, OneDrive)
$period = "D30"                          # Period to get data for (D7 = 7 days, D30 = 30 days, D90 = 90 days, D180 = 180 days)

##############################################
# Functions
##############################################

function ConnectToMSGraph {  
    try {
        Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $thumbprint -ErrorAction Stop
    }
    catch {
        Write-Host "Error connecting to MS Graph - $($Error[0].Exception.Message)" -ForegroundColor Red
        Exit
    }
}

function GetAppUserDetailsForDate($date) {

    try {
        $dateString = $date.ToString("yyyy-MM-dd")
        $outputPath = Join-Path -Path $dataFolder -ChildPath "M365AppUserReport-$dateString.csv"
        Get-MgReportM365AppUserDetail -Date $date -OutFile $outputPath

        # Upload the file to SharePoint
        # UploadFileToSPOGraph -path $outputPath -libraryName $appUsageLibraryName
        return $true
    }
    catch {
        Write-Error "Error getting app user details for date $date - $($_.Exception.Message)"
        return $false
    }
}

function PullAppUsageData {
    $today = Get-Date
    $twoDaysAgo = $today.AddDays(-2)
    for ($i = 0; $i -lt $daysToGoBack; $i++) {
        
        $date = $twoDaysAgo.AddDays(-$i)
        
        # Check if we already have the data for this date
        $appData = Get-ChildItem -Path $dataFolder -Filter "M365AppUserReport-$($date.ToString("yyyy-MM-dd")).csv"
        if ($appData) {

            ## Get first two lines of the file
            $firstTwoLines = Get-Content -Path $appData.FullName -TotalCount 2
            if ($firstTwoLines.Length -eq 2) {
                Write-Host "Data already exists for date $date"
                #UploadFileToSPOGraph -path $appData.FullName -libraryName $appUsageLibraryName
                continue
            }

            ## If length is not two then we have one line that is the header. So overwrite the file as empty
        }
    
        Write-Host "Getting app user details for date $date"
        GetAppUserDetailsForDate($date)
    }
}

function PullEmailUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "ExchangeUserReport-$($today.ToString("yyyy-MM-dd"))-$period.csv"
    
    try {
        Get-ChildItem -Path $outputPath -ErrorAction Stop
    }
    catch {
        try {
            #Get-MgReportEmailActivityUserDetail -Period $period -OutFile $outputPath
            Get-MgReportEmailActivityUserDetail -Period $period -OutFile $outputPath
        }
        catch {
            Write-Error "Error getting Email usage data - $($_.Exception.Message)"
            return $false
        }
    }

    $data = Import-Csv -Path $outputPath

    # Group by user principal name
    return $data | Group-Object -Property 'User Principal Name' -AsHashTable
}

function PullOneDriveUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "OneDriveActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"
    
    try {
        Get-ChildItem -Path $outputPath -ErrorAction Stop
    }
    catch { 

        try {
            #Get-MgReportOneDriveUsageAccountDetail -Period $period -OutFile $outputPath
            Get-MgReportOneDriveActivityUserDetail -Period $period -OutFile $outputPath
        }
        catch {
            Write-Error "Error getting OneDrive usage data - $($_.Exception.Message)"
            return $false
        }
    } 

    $data = Import-Csv -Path $outputPath

    # Group by user principal name
    return $data | Group-Object -Property 'User Principal Name' -AsHashTable
}

function PullSPOUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "SharePointActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"

    try {
        Get-ChildItem -Path $outputPath -ErrorAction Stop
    }
    catch {
        try {
            Get-MgReportSharePointActivityUserDetail -Period $period -OutFile $outputPath
        }
        catch {
            Write-Error "Error getting SharePoint usage data - $($_.Exception.Message)"
            return $false
        }
    }

    $data = Import-Csv -Path $outputPath
    # Group by user principal name
    return $data | Group-Object -Property 'User Principal Name' -AsHashTable
}

function PullTeamUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "TeamActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"

    try {
        Get-ChildItem -Path $outputPath -ErrorAction Stop
    }
    catch {
        try {
            Get-MgReportTeamUserActivityUserDetail -Period $period -OutFile $outputPath
        }
        catch {
            Write-Error "Error getting Teams usage data - $($_.Exception.Message)"
            return $false
        }
    }

    $data = Import-Csv -Path $outputPath
    # Group by user principal name
    return $data | Group-Object -Property 'User Principal Name' -AsHashTable
}

function GetUserDetail() {
    try {
        $today = Get-Date
        $dateString = $today.ToString("yyyy-MM-dd")
        $outputPath = Join-Path -Path $dataFolder -ChildPath "M365UserDetailReport-$dateString.csv"
        # Check if we already have the data for this date
        $userData = Get-ChildItem -Path $dataFolder -Filter "M365UserDetailReport-$dateString.csv"
        if ($userData) {
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

function UploadFileToSPOGraph($path, $libraryName) {
    # SharePoint Drive Id (Document Library)
    $driveId = Get-MgSiteDrive -SiteId $m365UsageDataSiteId | where { $_.Name -eq $libraryName } | Select-Object -ExpandProperty Id

    $fileProperties = Get-ChildItem -Path $path

    # Read the file content as a byte array
    $fileContent = [System.IO.File]::ReadAllBytes($path)

    # Destination file name
    $destinationName = "$($fileProperties.BaseName)-$($fileProperties.Extension)"

    # Upload the file to SharePoint
    $uploadReq = Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/drives/$driveId/root:/$destinationName`:/content" -Body $fileContent -ContentType "application/octet-stream"

    Write-Host "File: $($fileProperties.BaseName)  uploaded to $libraryName" -ForegroundColor Green
}

function UpdateReportSettings($displayConcealedNames) {
    $params = @{
        displayConcealedNames = $displayConcealedNames
    }
    
    Update-MgBetaAdminReportSetting -BodyParameter $params
}

function GetReportSettings {
    $reportSettings = Get-MgBetaAdminReportSetting
    return $reportSettings.DisplayConcealedNames
}

function GetUsersToCheck ($userDetailsReportGraphData) {

    $users = @()

    if ($checkAllUsers) {
        $users = $userDetailsReportGraphData | Select -Property "User Principal Name", "Assigned Products"
        return $users
    }

    if ($checkAllLicensedUsers) {
        return $userDetailsReportGraphData | where { IsUserLicensedForCopilot2 -userFromGraphReport $_ } | Select -Property "User Principal Name", "Assigned Products"
    }
    
    if (-not (Test-Path -Path $usersToCheckPath)) {
        Write-Error "UsersToCheck file not found"
        Exit
    }

    $usersToCheck = Get-Content -Path $usersToCheckPath
    foreach ($user in $usersToCheck) {
        $user = $user.Trim()
        $user = $userDetailsReportGraphData | where { $_.'User Principal Name' -eq $user } | Select -Property "User Principal Name", "Assigned Products"
        if ($user) {
            $users += $user
        }
    }

    return $users
}

function CombineAndTransformData($latestReportDate = $null) {
    $combinedDataHash = @{}
    $files = Get-ChildItem -Path $dataFolder -Filter M365AppUserReport*.csv
    foreach ($file in $files) {

        # Create an empty hashtable
        $dAUHash = @{}

        if ($null -ne $latestReportDate) {

            $reportDate = Get-DateFromFileName -fileName $file.Name
            if ($null -ne $reportDate) {
                if ($reportDate -gt $latestReportDate) {
                    ## New data, add to combined data
                    $data = Import-Csv -Path $file.FullName
                    
                    # Populate the hashtable with the CSV data
                    foreach ($row in $data) {
                        $dAUHash[$row.'User Principal Name'] = $row
                    }
                }
            }
        }
        else {
            ## If no latest report date then just add all data
            $data = Import-Csv -Path $file.FullName

            # Populate the hashtable with the CSV data
            foreach ($row in $data) {
                $dAUHash[$row.'User Principal Name'] = $row
            }
        }

        
        ## We can now iterate the daily hash and index to the user
        $combinedDataHash[$file.Name] = $dAUHash
    }

    return $combinedDataHash
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
    UpdatePlatformUsage -usersTotalAppUsage $usersTotalAppUsage -memberName "WindowsUser" -newValue $windowsUser
    UpdatePlatformUsage -usersTotalAppUsage $usersTotalAppUsage -memberName "MacUser" -newValue $macUser
    UpdatePlatformUsage -usersTotalAppUsage $usersTotalAppUsage -memberName "MobileUser" -newValue $mobileUser
    UpdatePlatformUsage -usersTotalAppUsage $usersTotalAppUsage -memberName "WebUser" -newValue $webUser

    ## Daily app counts
    $outlookDailyUsageCount = 0
    $wordDailyUsageCount = 0
    $excelDailyUsageCount = 0
    $powerpointDailyUsageCount = 0
    $teamsDailyUsageCount = 0
    $onenoteDailyUsageCount = 0

    $daysOfData = $userAppData.Count
    
    ## Go through each day and count the app usage
    foreach ($day in $userAppData) {

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
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "OutlookUsageDays" -Value $outlookDailyUsageCount -Force
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "WordUsageDays" -Value $wordDailyUsageCount -Force
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "ExcelUsageDays" -Value $excelDailyUsageCount -Force
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "PowerPointUsageDays" -Value $powerpointDailyUsageCount -Force
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "TeamsUsageDays" -Value $teamsDailyUsageCount -Force
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "OneNoteUsageDays" -Value $onenoteDailyUsageCount -Force

    ## Add total days of data for that user
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "DaysOfData" -Value $daysOfData -Force
    
    return $usersTotalAppUsage
}

function GetValueFromDataForUser($data, $upn, $property, $searchProperty = "User Principal Name") {
    if ($upn -eq "alex@groverale.onmicrosoft.com") {
        Write-Host "Getting value for $property for $upn"
    }
    ## Strage quirk of the hastable from CSV
    $usersData = $data[1][$upn]
    if ($null -eq $usersData.$property) {
        return 0
    }
    return $usersData.$property
}

function UpdatePlatformUsage($usersTotalAppUsage, $memberName, $newValue) {
    
    if ($usersTotalAppUsage | Get-Member -Name $memberName -MemberType NoteProperty -ErrorAction SilentlyContinue) {
        # We already have a property
        # If current value is Yes then we don't want to update, but if value is No then we can update
        if ($usersTotalAppUsage.$memberName -eq "Yes") {
            ## do nothing
        } else {
            $usersTotalAppUsage.$memberName = $newValue
        }
    }
    else {
        ## No Member, add it
        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name $memberName -Value $newValue
    }
}

function ProcessUser($user, $allUsersAppDataHash, $totalDaysOfData, $emailData, $oneDriveData, $spoData, $teamData) {
    # Index Rather than itterate through
    $userAppData = @()

    foreach($dayKey in $allUsersAppDataHash.Keys)
    {
        $dauHash = $allUsersAppDataHash[$dayKey]
        $usersDayData = $dauHash[$user.'User Principal Name']
        $userAppData += $usersDayData 
    }

    ## Go through each day record and check if the user has used the app
    $usersTotalAppUsage = GetUsersTotalAppUsage -userAppData $userAppData -upn $user.'User Principal Name'

    ## Add total days of data
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "TotalDaysOfData" -Value $totalDaysOfData -Force

    ## Is the user licensed for copilot
    $licened = IsUserLicensedForCopilot2 -userFromGraphReport $user
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "LicensedForCopilot" -Value $licened -Force

    if ($deepAnalysis) {
        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "DeepAnalysisPeriod" -Value $period -Force

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "EmailsSentInPeriod" -Value (GetValueFromDataForUser -data $emailData -upn $user.'User Principal Name' -property 'Send Count') -Force

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "ActiveFilesInOneDriveInPeriod" -Value (GetValueFromDataForUser -data $oneDriveData -upn $user.'User Principal Name' -property 'Viewed Or Edited File Count') -Force

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "ActiveFilesInSPOInPeriod" -Value (GetValueFromDataForUser -data $spoData -upn $user.'User Principal Name' -property 'Viewed Or Edited File Count') -Force

        $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "TotalAudioTimeMins" -Value ([Math]::Round((GetValueFromDataForUser -data $teamData -upn $user.'User Principal Name' -property 'Audio Duration In Seconds') / 60)) -Force
    }

    return $usersTotalAppUsage
}

function IsUserLicensedForCopilot2($userFromGraphReport) {
    
    # Sameple produc string 'POWER VIRTUAL AGENTS VIRAL TRIAL+OFFICE 365 E3 DEVELOPER+MICROSOFT POWER APPS PLAN 2 TRIAL+MICROSOFT FABRIC (FREE)'
    # Each produc string is seperated by a '+'
    $products = ($userFromGraphReport.'Assigned Products').Split('+')

    foreach ($product in $products) {
        if ($productSKUs.Contains($product)) {
            return $true
        }
    }

    return $false
}

##############################################
# Main
##############################################

## Initilaise the stopwatch
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

# ConnectToMSGraph

# # Update the report settings
$displayConcealedName = GetReportSettings

if ($displayConcealedName -eq $true) {
    UpdateReportSettings -displayConcealedNames $false
}

PullAppUsageData

if ($deepAnalysis) {

    Write-Host "Pulling and grouping deeper analysis data... please wait"

    $emailData = PullEmailUsageData -period $period

    $oneDriveData = PullOneDriveUsageData -period $period
    
    $spoData = PullSPOUsageData -period $period

    $teamData = PullTeamUsageData -period $period
}

## Processing

$userDetailsReportGraphData = GetUserDetail

if ($userDetailsReportGraphData -eq $false) {
    Write-Error "Error getting user details report data"
    Exit
}

$users = GetUsersToCheck -userDetailsReportGraphData $userDetailsReportGraphData


## Now the data part
$combinedDataHash = CombineAndTransformData

# Get Total days were of data
$files = Get-ChildItem -Path $dataFolder -Filter M365AppUserReport*.csv
$totalDaysOfData = $files.Count

## Go through each user and filter the data by user
$allUsersTotalAppUsage = @()

## Initilaise the CSV
$allUsersTotalAppUsage | Export-Csv -Path $reportFileLocation -NoTypeInformation -Force


# Initilaise progress bar
#cls
$today = Get-Date
$currentItem = 0
$percent = 0
Write-Progress -Activity "Processing User $currentItem / $($users.Count)" -Status "$percent% Complete:" -PercentComplete $percent

foreach ($user in $users) {

    ## Get the app data for the user
    $usersTotalAppUsage = ProcessUser -user $user -allUsersAppDataHash $combinedDataHash -totalDaysOfData $totalDaysOfData -emailData $emailData -oneDriveData $oneDriveData -spoData $spoData -teamData $teamData -existingReportData $existingReportData
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "Snapshot End Date" -Value $today.AddDays(-2).ToString("yyyy-MM-dd") -Force
    $usersTotalAppUsage | Add-Member -MemberType NoteProperty -Name "Snapshot Start Date" -Value $today.AddDays(-$daysToGoBack-2).ToString("yyyy-MM-dd") -Force
    $usersTotalAppUsage | Export-Csv -Path $reportFileLocation -NoTypeInformation -Append
    

    ## Update progress bar
    $currentItem++
    $percent = [Math]::Round(($currentItem / $users.Count) * 100)
    Write-Progress -Activity "Processed User $currentItem / $($users.Count)" -Status "$percent% Complete:" -PercentComplete $percent

}

## Close the progress bar
Write-Progress -Activity "Processed User $currentItem / $($users.Count)" -Status "100% Complete:" -Completed


## Upload the CSV to SPO
# UploadFileToSPOGraph -path $reportFileLocation -libraryName $appUsageProcessedLibraryName

if ($displayConcealedName -eq $true) {
    UpdateReportSettings -displayConcealedNames $true
}

Write-Host "Script completed in $($stopWatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green

