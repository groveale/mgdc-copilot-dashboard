## This will create a self-signed certificate for use with authenticating MSGraph API calls
## A .cer file will be created in the same directory as the script, this should be uploaded to the app reg

$certname = "copilot-dashboard"    ## Replace {certificateName}
$cert = New-SelfSignedCertificate -Subject "CN=$certname" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
Export-Certificate -Cert $cert -FilePath "$certname.cer"   ## Specify your preferr