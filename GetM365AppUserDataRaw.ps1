#############################################
# Description: 
# This script pulls M365 app usage data from MSGraph and saves the output into an SPO library.
# This data can then be ingested into a data warehouse for further analysis.
#
# Alex Grover - alexgrover@microsoft.com
#
# VersionLog : 
# 2024-01-31 - Initial version
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
#$timeStamp = Get-Date -Format "yyyyMMddHHmmss"

#$usageSPOSiteUrl = "https://groverale.sharepoint.com/sites/M365UsageData"
$m365UsageDataSiteId = "7a838fca-e704-4c57-a6a8-a73a8029bca2"
$appUsageLibraryName = "M365AppUsageReports"
$outlookUsageLibraryName = "OutlookUsageReports"
$oneDriveUsageLibraryName = "OneDriveUsageReports"
$spoUsageLibraryName = "SharePointUsageReports"
$teamUsageLibraryName = "TeamsUsageReports"

# Data folder
$dataFolder = "C:\scratch\m365appusage"

# Days to go back (max is 28)
$daysToGoBack = 28

# Deeper Analysis
$deepAnalysis = $true                    # If true, deeper analysis will be done (Email, OneDrive)
$period = "D7"                          # Period to get data for (D7 = 7 days, D30 = 30 days, D90 = 90 days, D180 = 180 days)

##############################################
# Functions
##############################################

function ConnectToMSGraph {  
    try {
        # Disconnect if already connected
        #Disconnect-MgGraph
        if ($delegatedAuth) {
            Connect-MgGraph -Scopes Reports.Read.All, User.Read.All -ErrorAction Stop
            return
        }

        Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $thumbprint -ErrorAction Stop
    }
    catch {
        Write-Host "Error connecting to MS Graph - $($Error[0].Exception.Message)" -ForegroundColor Red
        Exit
    }
}

function Get-AppUserDetailsForDate($date) {

    try {
        $dateString = $date.ToString("yyyy-MM-dd")
        $outputPath = Join-Path -Path $dataFolder -ChildPath "M365AppUserReport-$dateString.csv"
        Get-MgReportM365AppUserDetail -Date $date -OutFile $outputPath

        # Upload the file to SharePoint
        UploadFileToSPOGraph -path $outputPath -libraryName $appUsageLibraryName
        return $true
    }
    catch {
        Write-Error "Error getting app user details for date $date - $($_.Exception.Message)"
        return $false
    }
}

function PullAppUsageData {
    for ($i = 0; $i -lt $daysToGoBack; $i++) {
        $today = Get-Date
        $date = $today.AddDays(-$i)
        
        # Check if we already have the data for this date
        $appData = Get-ChildItem -Path $dataFolder -Filter "M365AppUserReport-$($date.ToString("yyyy-MM-dd")).csv"
        if ($appData) {

            ## Get first two lines of the file
            $firstTwoLines = Get-Content -Path $appData.FullName -TotalCount 2
            if ($firstTwoLines.Length -eq 2) {
                Write-Host "Data already exists for date $date"
                UploadFileToSPOGraph -path $appData.FullName -libraryName $appUsageLibraryName
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
            UploadFileToSPOGraph -path $outputPath -libraryName $outlookUsageLibraryName
            return $true
        }
    }
    catch {
        try {
            #Get-MgReportEmailActivityUserDetail -Period $period -OutFile $outputPath
            Get-MgReportEmailActivityUserDetail -Period $period -OutFile $outputPath
            # Upload the file to SharePoint
            UploadFileToSPOGraph -path $outputPath -libraryName $outlookUsageLibraryName
            return $true
        }
        catch {
            Write-Error "Error getting Email usage data - $($_.Exception.Message)"
            return $false
        }
    }
    
}

function PullOneDriveUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "OneDriveActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"
    
    try {
        $existingReport = Get-ChildItem -Path $outputPath -ErrorAction Stop
        if ($existingReport) {
            UploadFileToSPOGraph -path $outputPath -libraryName $oneDriveUsageLibraryName
            return $true   
        }
    }
    catch { 

        try {
            #Get-MgReportOneDriveUsageAccountDetail -Period $period -OutFile $outputPath
            Get-MgReportOneDriveActivityUserDetail -Period $period -OutFile $outputPath

            # Upload the file to SharePoint
            UploadFileToSPOGraph -path $outputPath -libraryName $oneDriveUsageLibraryName

            return $true
        }
        catch {
            Write-Error "Error getting OneDrive usage data - $($_.Exception.Message)"
            return $false
        }
    }  
}

function PullSPOUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "SharePointActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"

    try {
        $existingReport = Get-ChildItem -Path $outputPath -ErrorAction Stop
        if ($existingReport) {
            UploadFileToSPOGraph -path $outputPath -libraryName $spoUsageLibraryName
            return $true  
        }
    }
    catch {
        try {
           
        
            #Get-MgReportSharePointSiteUsageDetail -Period $period -OutFile $outputPath
            Get-MgReportSharePointActivityUserDetail -Period $period -OutFile $outputPath
            # Upload the file to SharePoint
            UploadFileToSPOGraph -path $outputPath -libraryName $spoUsageLibraryName

            return $true
        }
        catch {
            Write-Error "Error getting SharePoint usage data - $($_.Exception.Message)"
            return $false
        }
    }
}

function PullTeamUsageData ($period) {
    $today = Get-Date
    $outputPath = Join-Path -Path $dataFolder -ChildPath "TeamActivityUserDetail-$($today.ToString("yyyy-MM-dd"))-$period.csv"

    try {
        $existingReport = Get-ChildItem -Path $outputPath -ErrorAction Stop
        if ($existingReport) {
            UploadFileToSPOGraph -path $outputPath -libraryName $teamUsageLibraryName
            return $true  
        }
    }
    catch {
        try {
            Get-MgReportTeamUserActivityUserDetail -Period $period -OutFile $outputPath
            # Upload the file to SharePoint
            UploadFileToSPOGraph -path $outputPath -libraryName $teamUsageLibraryName
            return $true
        }
        catch {
            Write-Error "Error getting Teams usage data - $($_.Exception.Message)"
            return $false
        }
        
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

PullAppUsageData

if ($deepAnalysis) {
    $emailData = PullEmailUsageData -period $period

    $oneDriveData = PullOneDriveUsageData -period $period
    
    $spoData = PullSPOUsageData -period $period

    $teamData = PullTeamUsageData -period $period
}

if ($displayConcealedName -eq $true) {
    UpdateReportSettings -displayConcealedNames $true
}

Write-Host "Script completed in $($stopWatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green

