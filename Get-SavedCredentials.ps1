function Get-SavedCredentials {
    <#
    .SYNOPSIS
        Returns a PSCredential from an encrypted file.

    .DESCRIPTION
        Returns a PSCredential from an encrypted file.

    .PARAMETER Title
        The name of the username and password pair. This allows multiple accounts to be saved such as a normal account and an administrator account.

    .PARAMETER VaultPath
        The file path of the encrypted file for saving the username and password pair.

    .PARAMETER Renew
        Prompts the user for a new password for an existing pair.

    .EXAMPLE
        Enter-PsSession -ComputerName Computer -Credential (Get-SavedCredentials)

    .EXAMPLE
        $Credential = Get-SavedCredentials -Title Normal -VaultPath c:\temp\myfile.json

    .LINK
        https://github.com/gbuktenica/GetSavedCredentials

    .NOTES
        Author     : Glen Buktenica
        Change Log : 20200314 Initial Build
    #>
    [CmdletBinding()]
    Param(
        [string]$Title = "Default",
        [string]$VaultPath = "$env:USERPROFILE\PowerShellHash.json",
        [switch]$Renew
    )
    $JsonChanged = $false
    if (-not (Test-path -Path $VaultPath)) {
        # Create a new Json object if the file does not exist.
        $Json = "{`"$Title`": { `"username`": `"`", `"password`": `"`" }}" | ConvertFrom-Json
        $JsonChanged = $true
    }
    else {
        try {
            # Read the file if it already exists
            $Json = Get-Content -Raw -Path $VaultPath | ConvertFrom-Json -ErrorAction Stop
        }
         catch {
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
    if ($Json.$Title.username.Length -eq 0) {
        #Prompt user for username if it is not saved.
        $Message = "Enter User name for> $Title"
        $Username = Read-Host $Message -ErrorAction Stop
        ($Json.$Title.username) = $Username
        $JsonChanged = $true
    }
    if ($Json.$Title.password.Length -eq 0 -or $Renew) {
         #Prompt user for Password if it is not saved.
        $Message = "Enter Password for> " + $Json.$Title.username
        $secureStringPwd = Read-Host $Message -AsSecureString -ErrorAction Stop
        $secureStringText = $secureStringPwd | ConvertFrom-SecureString
        $Json.$Title.password = $secureStringText
        $JsonChanged = $true
    }
    If ($JsonChanged) {
        # Save the Json object to file if it has changed.
        $Json | ConvertTo-Json -depth 3 | Set-Content $VaultPath -ErrorAction Stop
    }
    # Build the PSCredential object and export it.
    $Username = $Json.$Title.username
    $SecurePassword = $Json.$Title.password | ConvertTo-SecureString
    New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword -ErrorAction Stop
}