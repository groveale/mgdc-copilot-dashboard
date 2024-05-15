$datestring = (get-date).ToString("yyyyMMdd-hhmm")
$cookiesCSVFilePath = ".\cookies.csv"
$cookiesTXTFilePath = ".\cookies.txt"

$WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$cookiesCSV = Import-CSV $cookiesCSVFilePath
$cookiesTxt = Get-Content $cookiesTXTFilePath

# foreach ($cookie in $cookies) {
#     $newCookie = New-Object System.Net.Cookie
#     $newCookie.Name = $cookie.Name
#     $newCookie.Value = $cookie.Value
#     $newCookie.Domain = $cookie.Domain
#     $WebSession.Cookies.Add($newCookie)
# }


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


$headerParams = @{
    "ContentType" = "application/json"
    "Cookie" = $cookiesTXT
    ##"Authorization" = "Bearer $authTokenTXT"
}

$queryOptions = @{
    Method     = "GET"
    URI        = "https://admin.microsoft.com/admin/api/reports/GetDetailDataV3?ServiceId=MicrosoftOffice&CategoryId=MicrosoftCopilot&Report=CopilotActivityReport&active_view=Details"
    Headers    = $headerParams
    WebSession = $WebSession
} 

$copilotActivityUserList = @()

try {
    $apiResult = Invoke-RestMethod @queryOptions -ErrorAction Stop
    $usgageData = ($apiResult.Output | ConvertFrom-Json).value

    $reportRefreshDate = $usgageData[0].reportRefreshDate

    foreach ($user in $usgageData) {

        ## If the user lastactivity is not the same as the report refresh date then no daily activity
        if ($user.lastActivityDate -ne $user.reportRefreshDate) {
            continue
        }

        ## need a new object to add data too
        $userActivtyObj = [PSCustomObject]@{
            "ReportDate" = $user.reportRefreshDate
            "UPN" = $user.userPrincipalName
            "DisplayName" = $user.displayName
        }

        ## LastActivity in last 7 days
        $last7Days = $user.copilotActivityUserDetailsByPeriod[0]

        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDateM365Chat -propertyName "DailyM365ChatActivity"
        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDateTeams -propertyName "DailyTeamsActivity"
        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDateOutlook -propertyName "DailyOutlookActivity"
        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDateWord -propertyName "DailyWordActivity"
        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDateExcel -propertyName "DailyExcelActivity"
        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDatePowerPoint -propertyName "DailyPowerPointActivity"
        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDateOneNote -propertyName "DailyOneNoteActivity"
        IfDailyActivityForApp -userActivtyObj $userActivtyObj -reportRefreshDate $user.reportRefreshDate -appLastActivityData $last7Days.lastActivityDateLoop -propertyName "DailyLoopActivity"
    
        $copilotActivityUserList += $userActivtyObj
    }

    $copilotActivityUserList | Export-Csv -Path ".\CopilotDailyActivityUserList-$reportRefreshDate.csv" -NoTypeInformation

    ## Upload the file to SharePoint

}
catch {
    Write-Output $_.exception.message
}