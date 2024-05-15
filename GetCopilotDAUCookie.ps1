#############################################
# Description: 
# This script pulls Copilot app usage data from private report APIs. It uses the reports 
# to build a list of users and their last activity date for the Copilot app. This is saved in SPO
#
# The report must be run daily. Otherwise we miss a day of data.
#
# Alex Grover - alexgrover@microsoft.com
#
# VersionLog : 
# 2024-03-07 - Initial version
#
##############################################
# Dependencies
##############################################
## Requires the following modules:
try {
    Import-Module Microsoft.Graph.Beta.Reports
    Import-Module Microsoft.Graph.Sites
}
catch {
    Write-Error "Error importing modules required modules - $($Error[0].Exception.Message))"
    Exit
}

# Graph Permissions
# ReportSettings.ReadWrite.All
# Sites.Selected


##############################################
# Variables
##############################################

$clientId = "4b7482f3-5fac-470b-8f6a-69b59c87c59f"
$tenantId = "groverale.onmicrosoft.com"
$thumbprint = "BD4D7AC2DBCD010E04194D467AC996F486512A49"

# Log file location (timestamped with script start time)
#$timeStamp = Get-Date -Format "yyyyMMddHHmmss"

#$usageSPOSiteUrl = "https://groverale.sharepoint.com/sites/M365UsageData"
$m365UsageDataSiteId = "7a838fca-e704-4c57-a6a8-a73a8029bca2"
$copilotUsageLibraryName = "CopiloptAppDailyReports"

$cookiesTXTFilePath = ".\cookies.txt"

# Data folder
$dataFolder = "C:\scratch\copilotappusage"

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

function IfDailyActivityForApp ($userActivtyObj, $appLastActivityData, $reportRefreshDate, $propertyName)
{
    if ($appLastActivityData -eq $reportRefreshDate) 
    { 
        $userActivtyObj | Add-Member -MemberType NoteProperty -Name $propertyName -Value True 
    }
    else 
    { 
        $userActivtyObj | Add-Member -MemberType NoteProperty -Name $propertyName -Value False
    }
}

##############################################
# Main
##############################################

## Initilaise the stopwatch
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

ConnectToMSGraph

# Update the report settings
$displayConcealedName = GetReportSettings

if ($displayConcealedName -eq $true) {
    UpdateReportSettings -displayConcealedNames $false
}



if ($displayConcealedName -eq $true) {
    UpdateReportSettings -displayConcealedNames $true
}

# Clean up the data folder but don't delete the folder
Remove-Item -Path $dataFolder\* -Recurse -Force

Write-Host "Script completed in $($stopWatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green

