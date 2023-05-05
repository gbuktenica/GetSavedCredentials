.\Get-SavedCredentials.ps1 -List

$Title = Read-Host "Enter Credential Title"

$Credential = .\Get-SavedCredentials.ps1 -Title $Title

ConvertFrom-SecureString $Credential.Password -AsPlainText