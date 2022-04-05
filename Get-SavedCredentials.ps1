function Get-SavedCredentials {
    <#
    .SYNOPSIS
        Returns a PSCredential from an encrypted file.

    .DESCRIPTION
        Returns a PSCredential from a file encrypted using Windows Data Protection API (DAPI).
        If the file does not exist the user will be prompted for the username and password the first time.
        The GPO setting Network Access: Do not allow storage of passwords and credentials for network authentication must be set to Disabled
        otherwise the password will only persist for the length of the user session.

    .PARAMETER Title
        The name of the username and password pair. This allows multiple accounts to be saved such as a normal account and an administrator account.

    .PARAMETER VaultPath
        The file path of the encrypted Json file for saving the username and password pair.
        Default value is c:\users\<USERNAME>\PowerShellHash.json"

    .PARAMETER Renew
        Prompts the user for a new password to overwrite an existing secret.
        To be used after a password change.

    .PARAMETER SecureString
        Used for storing secrets that do not have a username.
        Returns a SecureString instead of a PSCredential Object.

    .EXAMPLE
        Enter-PsSession -ComputerName Computer -Credential (Get-SavedCredentials)

    .EXAMPLE
        $Credential = Get-SavedCredentials -Title Normal -VaultPath c:\temp\myFile.json

    .LINK
        https://github.com/gbuktenica/GetSavedCredentials

    .NOTES
        License      : MIT License
        Copyright (c): 2020 Glen Buktenica
        Release      : v1.1.0 20220405
    #>
    [CmdletBinding()]
    Param(
        [string]$Title = "Default",
        [string]$VaultPath = "$env:USERPROFILE\PowerShellHash.json",
        [switch]$Renew,
        [switch]$SecureString
    )
    $JsonChanged = $false
    if (-not (Test-path -Path $VaultPath)) {
        # Create a new Json object if the file does not exist.
        $Json = "{`"$Title`": { `"username`": `"`", `"password`": `"`" }}" | ConvertFrom-Json
        $JsonChanged = $true
    } else {
        try {
            # Read the file if it already exists
            $Json = Get-Content -Raw -Path $VaultPath | ConvertFrom-Json -ErrorAction Stop
        } catch {
            # If the file is corrupt overwrite it.
            $Json = "{`"$Title`": { `"username`": `"`", `"password`": `"`" }}" | ConvertFrom-Json
            $JsonChanged = $true
        }
    }
    if ($Json.$Title.length -eq 0) {
        # Create a new Username \ Password key if it is new.
        $TitleContent = " { `"username`":`"`", `"password`":`"`" }"
        $Json | Add-Member -Name $Title -value (Convertfrom-Json $TitleContent) -MemberType NoteProperty
        $JsonChanged = $true
    }
    if ($SecureString) {
        if ($Json.$Title.username.Length -eq 0) {
            ($Json.$Title.username) = "SecureString"
            $JsonChanged = $true
        }
    } else {
        if ($Json.$Title.username.Length -eq 0) {
            #Prompt user for username if it is not saved.
            $Message = "Enter User name for> $Title"
            $Username = Read-Host $Message -ErrorAction Stop
            ($Json.$Title.username) = $Username
            $JsonChanged = $true
        }
    }
    if ($Json.$Title.password.Length -eq 0 -or $Renew) {
        #Prompt user for Password if it is not saved.
        $Message = "Enter Password for> " + $Json.$Title.username
        $secureStringPwd = Read-Host $Message -AsSecureString -ErrorAction Stop
        $secureStringText = $secureStringPwd | ConvertFrom-SecureString
        $Json.$Title.password = $secureStringText
        $JsonChanged = $true
    }

    $Username = $Json.$Title.username
    if ($SecureString) {
        try {
            # Export the secure string.
            $Json.$Title.password | ConvertTo-SecureString -ErrorAction Stop
        } catch {
            # If exporting the secure string failed for any reason delete it and run the function
            # again which will prompt the user for a password.
            $TitleContent = " { `"username`":`"`", `"password`":`"`" }"
            $Json | Add-Member -Name $Title -value (Convertfrom-Json $TitleContent) -MemberType NoteProperty -Force
            $Json | ConvertTo-Json -depth 3 | Set-Content $VaultPath -ErrorAction Stop
            Get-SavedCredentials -Title $Title -VaultPath $VaultPath -SecureString
        }
    } else {
        try {
            # Build the PSCredential object and export it.
            $SecurePassword = $Json.$Title.password | ConvertTo-SecureString -ErrorAction Stop
            New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword -ErrorAction Stop
        } catch {
            # If building the credential failed for any reason delete it and run the function
            # again which will prompt the user for username and password.
            $TitleContent = " { `"username`":`"`", `"password`":`"`" }"
            $Json | Add-Member -Name $Title -value (Convertfrom-Json $TitleContent) -MemberType NoteProperty -Force
            $Json | ConvertTo-Json -depth 3 | Set-Content $VaultPath -ErrorAction Stop
            Get-SavedCredentials -Title $Title -VaultPath $VaultPath
        }
    }

    If ($JsonChanged) {
        # Save the Json object to file if it has changed.
        $Json | ConvertTo-Json -depth 3 | Set-Content $VaultPath -ErrorAction Stop
    }
}
# Get Secure String
$SecureString = Get-SavedCredentials -Title "TestString" -SecureString
# Get Credential Object
$Credential = Get-SavedCredentials -Title "TestCredential"

Write-Output "Secure string converted to plain text:"
ConvertFrom-SecureString $SecureString -AsPlainText
Write-Output " "
Write-Output "Username and Plain text password for Credential Object:"
$Credential.Username
ConvertFrom-SecureString $Credential.Password -AsPlainText