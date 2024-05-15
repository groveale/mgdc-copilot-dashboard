$tenantId = "75e67881-b174-484b-9d30-c581c7ebc177"
$url = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$body = @{
    client_id     = "cd85557e-65a9-4854-b879-2671dfaee51a"
    grant_type    = "authorization_code"
    redirect_uri  = "https://oauth.pstmn.io/v1/browser-callback"
    client_secret = ""
    scope         = "profile openid email https://graph.microsoft.com/EnterpriseResource.Read https://graph.microsoft.com/Project.Read https://graph.microsoft.com/ProjectWebAppReporting.Read https://graph.microsoft.com/User.Read offline_access"
    code          = "0.ARoAgXjmdXSxS0idMMWBx-vBd35Vhc2pZVRIuHkmcd-u5RoNAc0.AgABAAIAAADnfolhJpSnRYB1SVj-Hgd8AgDs_wUA9P-HF1IF6OrqgJnL-liSDerzdy593qbd1jAMjM5cWPLipJQz2esG3Ku7EzVmH41E2mum9PhQx6jXaJUeGkYBycxzH8avVflvdRmuLG9wMt-tXU1wZvqEkOaMGgfID234FYl-_P7iY4TNFnWnc8922y0tGmRnfykZQf_PnONJpToKP4TrQ_h9qRK6oiUJtp2r3libb3H8ACrMv81xiJMg3vRU9-nMMDIDOlLZJ8y1TnR0NRtcSvN8gclbjRUwWneYyN5EhbnDJifPS8YonSeKCWX1zCPhzWi2KZdzNU81aUMvn-r8rxfNDk2YdSk1ECO5v9KZ8Juv_SwMwhGB6jnF5hcefnSXbiEr_ZfeFltwgQmklHGw3ysceJnsoHS_fisw5u4Y_VYyGeDoIsF1wMGo-MXN-QfuoHed2gNHREFXmSbaBLs2x__-_szSvBAcR9yQCfHLCAqjf_KLh1GOWw6KnAozKeoaTwP4Ng-c4jD-pjohCSgK0rR2azHsuYaRM0FJGt-lIoaYjlu2ZYjkpofaLxGHhSJCqPTmtRonO6yKhi5l4g92B6yd1408fUIsByoRZQ2_AnXNz6x0TmxscZEIau9tcLlL2O1E1RvB-B_qOiy4k-aCZUk-4TbIuBFVfqSdsCTV6k9OoS4gD_IuD_nMNhxak4FNcZUoegM3MycWPIJjHeCC7tXNlG-DVu0nd9-V_fSziPtxF3p4uZSLKLvJV3Pr8y2ouksbHIQa9gByfehdaZyLmPvdKWDw3H634WDMydcpa1jjEmFfbPmvEK_7hKCYVHwv1hlzejdCR7zUW38Q0WJyRDFznLY3EWg7NJQpi-uo9h0lrPKeZZV8RY6-HSM18-WTjo0CtxjzF_WEgYLWigXoW5edzdvPPI8UN0GbuwGzV1E_KKWhvXbHTKQrpQpvDfr31epQSU077JFdJtR4Vxw1OEW5DAl3-rlRYI6ycbgSWhjq00qoPtiUOOn4Ad5zYrQPvVMMx_kNZSGMyfL6GLwsbXeU2W2H3_mPfv6Pp8yUhU-n4w"
}

$response = Invoke-RestMethod -Uri $url -Method Post -Body $body

$response


$body = @{
    client_id      = "cd85557e-65a9-4854-b879-2671dfaee51a"
    grant_type     = "refresh_token"
    refresh_token  = $response.refresh_token
    client_secret  = ""
    scope          = "https://groverale.sharepoint.com/.default"
}

$spoResponse = Invoke-RestMethod -Uri $url -Method Post -Body $body

$spoResponse


$projectOnlineAPI = "https://groverale.sharepoint.com/sites/pwa/_api/projectdata/Projects"  # Replace this with your actual endpoint URL

$headers = @{
    "Authorization" = "Bearer $($spoResponse.access_token)"
}

$pwaResponse = Invoke-RestMethod -Uri $projectOnlineAPI -Method Get -Headers $headers

$pwaResponse

