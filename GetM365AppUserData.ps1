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
# - TotalDaysOfData (Total number of days of data)
# - LicensedForCopilot (If the users license is cable of adding Copilot e.g. E3 / E5)
# - TotalDaysOfData (Total number of days of data)
#
# This report can be used to understand heavy users of M365. Aka good candidates for Copilot.
#              
# Todo:
# - Add support for getting users emails sent in period [Content generation]
# - Add support for total files created in SPO / Teams [Content generation]
# - Add support for users total Teams Meetings / Chats [Summarization]
# - Add support for users MSSearch queries (may not be possible) [Content Search]
#
# Alex Grover - alexgrover@microsoft.com
#
# VersionLog : 
# 2023-09-27 - Initial version
# 2023-10-03 - Fixed bug in returning user platform usage
#
#
#
##############################################
# Dependencies
##############################################
## Requires the following modules:
try {
    Import-Module Microsoft.Graph.Reports
    Import-Module Microsoft.Graph.Users
}
catch {
    Write-Error "Error importing modules required modules - $($Error[0].Exception.Message))"
    Exit
}

# Graph Permissions
# User.Read.All
# Reports.Read.All


##############################################
# Variables
##############################################

# Auth
$delegatedAuth = $true                 # If true, delegated auth will be used. If false, app only auth will be used

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
$checkAllUsers = $true                 # If true, all users in the tenant will be checked
$checkAllLicensedUsers = $false         # If true, only users with licenses in the $licenseSKUs array will be checked
$usersToCheckPath = "UsersToCheck.txt"  # If not checking all users / all licensed users, this file will be used to get the list of users to check

# Licenses to check
$licenseSKUs = @(
    "6fd2c87f-b296-42f0-b197-1e91e994b900", # Microsoft 365 E3
    "c7df2760-2c81-4ef7-b578-5b5392b571df", # Microsoft 365 E5
    "189a915c-fe4f-4ffa-bde4-85b9628d07a0"  # DeveloperPack (Gives E3 license)
)

##############################################
# Functions
##############################################

function ConnectToMSGraph 
{  
    try{

        if($delegatedAuth) {
            Connect-MgGraph -Scopes "User.Read.All, Reports.Read.All" -UseDeviceAuthentication
            return
        }

        Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $thumbprint
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
    $files = Get-ChildItem -Path $dataFolder -Filter *.csv
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
    
        # If 2 days ago or less allways get new data
        if($i -le 2) {
            Write-Host "Getting app user details for date $date"
            Get-AppUserDetailsForDate($date)
            continue
        }
    
        # Check if we already have the data for this date
        $appData = Get-ChildItem -Path $dataFolder -Filter "M365AppUserReport-$($date.ToString("yyyy-MM-dd")).csv"
        if($appData) {
            Write-Host "Data already exists for date $date"
            continue
        }
    
        Write-Host "Getting app user details for date $date"
        Get-AppUserDetailsForDate($date)
    }
}

function GetUsersToCheck {

    $users = @()

    if ($checkAllUsers) {
        return Get-MgUser -All -Property UserPrincipalName, Id
    }

    if ($checkAllLicensedUsers) {
        $allUsers = Get-MgUser -All -Property UserPrincipalName, Id
        foreach($user in $allUsers) {
            if (IsUserLicensedForCopilot -userId $user.Id)
            {
                $users += $user
            }
        }
        return $users
    }
    
    if (-not (Test-Path -Path $usersToCheckPath)) {
        Write-Error "UsersToCheck file not found"
        Exit
    }

    $usersToCheck = Get-Content -Path $usersToCheckPath
    foreach($user in $usersToCheck) {
        $user = $user.Trim()
        $user = Get-MgUser -UserId $user -Property UserPrincipalName, Id
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

function GetUsersTotalAppUsage($userAppData, $upn) {
    $usersTotalAppUsage = @{}
    $usersTotalAppUsage.Add("User Principal Name", $upn)

    ## If we get a single day where the user has used the app from a platform, 
    ## we will assume they are a user of that platform
    $windowsUser = ($userAppData | where { $_.Windows -eq "Yes" }).Length -gt 0
    $macUser = ($userAppData | where { $_.Mac -eq "Yes" }).Length -gt 0
    $mobileUser = ($userAppData | where { $_.Mobile -eq "Yes" }).Length -gt 0
    $webUser = ($userAppData | where { $_.Web -eq "Yes" }).Length -gt 0

    ## Add platform usage
    $usersTotalAppUsage.Add("WindowsUser", $windowsUser)
    $usersTotalAppUsage.Add("MacUser", $macUser)
    $usersTotalAppUsage.Add("MobileUser", $mobileUser)
    $usersTotalAppUsage.Add("WebUser", $webUser)

    ## Daily app counts
    $outlookDailyUsageCount = 0
    $wordDailyUsageCount = 0
    $excelDailyUsageCount = 0
    $powerpointDailyUsageCount = 0
    $teamsDailyUsageCount = 0
    $onenoteDailyUsageCount = 0

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
    $usersTotalAppUsage.Add("OutlookUsageDays", $outlookDailyUsageCount)
    $usersTotalAppUsage.Add("WordUsageDays", $wordDailyUsageCount)
    $usersTotalAppUsage.Add("ExcelUsageDays", $excelDailyUsageCount)
    $usersTotalAppUsage.Add("PowerPointUsageDays", $powerpointDailyUsageCount)
    $usersTotalAppUsage.Add("TeamsUsageDays", $teamsDailyUsageCount)
    $usersTotalAppUsage.Add("OneNoteUsageDays", $onenoteDailyUsageCount)
    
    return $usersTotalAppUsage
}

##############################################
# Main
##############################################

ConnectToMSGraph

PullAppUsageData

#PullEmailUsageData

$users = GetUsersToCheck

## Now the data part
$combinedData = CombineAndTransformData

# Get Total days were of data
$files = Get-ChildItem -Path $dataFolder -Filter *.csv
$totalDaysOfData = $files.Count

## Go through each user and filter the data by user
$allUsersTotalAppUsage = @()
foreach($user in $users) {
    $userAppData = $combinedData | where { $_.'User Principal Name' -eq $user.UserPrincipalName }
    
    ## Go through each day record and check if the user has used the app
    $usersTotalAppUsage = GetUsersTotalAppUsage -userAppData $userAppData -upn $user.UserPrincipalName

    ## Add total days of data
    $usersTotalAppUsage.Add("TotalDaysOfData", $totalDaysOfData)

    ## Is the user licensed for copilot
    $usersTotalAppUsage.Add("LicensedForCopilot", (IsUserLicensedForCopilot -userId $user.Id))

    ## Emails Read and Eamil Sent

    $allUsersTotalAppUsage += $usersTotalAppUsage
}

## Output the data
$allUsersTotalAppUsage | Export-Csv -Path $reportFileLocation -NoTypeInformation
