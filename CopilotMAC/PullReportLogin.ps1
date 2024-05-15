$adminPortal = "https://admin.microsoft.com/Adminportal/Home#/homepage"
$copilotUsageReport = "https://admin.microsoft.com/admin/api/reports/GetDetailDataV3?ServiceId=MicrosoftOffice&CategoryId=MicrosoftCopilot&Report=CopilotActivityReport&active_view=Details"
$downloadURL = "https://login.microsoftonline.com/common/oauth2/authorize?client_id=507bc9da-c4e2-40cb-96a7-ac90df92685c&response_mode=form_post&response_type=code%20id_token&scope=openid%20profile&state=OpenIdConnect.AuthenticationProperties%3Dg9N7fycSV45RxSVfjHsqfoB_yHTGk_ZcyOnGo01WpTi3wWFcyDq6N7SjpdKi9gmoXJgPVoyT4r25vurkZddn6ufLvOtZF7pOusJNbQiFpvUYTJyLEgmfp_l_ZDKjsoiT7Q9ftRLB5H5txECi1eiYIfMAhLMWvjjVqD915uFLLro5lAIiNKhLhD_x5Gitj6GdNMlZA4D4xNJ2WdlhTNahc-Ax2Ox_yNqGBSW4ZPZhBSztlpfcusv8jpWpmLuHmbQQDE52ZWCrlHwiFIoE_2Gx2HiNeCTg2fT_1BFABLshPcLLhWeuaA5DMYldoiii-ZHme2MeM-Q2mf8A7Gf-dWan8g&nonce=638442993627168206.Y2RhOTI2NDktOTRiZS00OGQ4LWFmY2MtMTFkMzMzMmMzZWI0MGY2ZTA1NjctZmZjNC00YmQ5LWEyMTgtMDFmMTUwNzRlZDdh&redirect_uri=https%3A%2F%2Freportsncu.office.com&post_logout_redirect_uri=reportsncu.office.com&x-client-SKU=ID_NET472&x-client-ver=6.26.0.0"

Write-host " -----------------------------------------" -ForegroundColor Green
Write-Host "  =====>>>> PortalURL:", $adminPortal
Start-Process -FilePath 'iexplore.exe' -ArgumentList $adminPortal
Write-Host "      Enter your credentials to load the MAC" -ForegroundColor Magenta
Read-Host -Prompt "Press Enter to continue ...."


Write-host " -----------------------------------------" -ForegroundColor Green
Write-Host "  =====>>>> CopilotUsageReport:", $copilotUsageReport
Start-Process -FilePath 'iexplore.exe' -ArgumentList $downloadURL

##Write-Host "      Save the 100 channels (from", $($i*100), "to", $(($i+1)*100), ") into the folder $streamJSONfolder respecting the name channels100.json" -ForegroundColor Magenta
Read-Host -Prompt "Press Enter to continue ...."