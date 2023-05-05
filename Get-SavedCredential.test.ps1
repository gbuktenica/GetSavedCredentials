# List all existing secrets
.\Get-SavedCredentials.ps1 -List
# Get Secure String
$SecureString = .\Get-SavedCredentials.ps1 -Title "TestString" -SecureString
# Get Credential Object
$Credential = .\Get-SavedCredentials.ps1 -Title "TestCredential"

Write-Output "Secure string converted to plain text:"
ConvertFrom-SecureString $SecureString -AsPlainText
Write-Output " "
Write-Output "Username and Plain text password for Credential Object:"
$Credential.Username
ConvertFrom-SecureString $Credential.Password -AsPlainText