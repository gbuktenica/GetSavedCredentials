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
        Default value is "Default"

    .PARAMETER VaultPath
        The file path of the encrypted Json file for saving the username and password pair.
        Default value is "c:\users\<USERNAME>\PowerShellHash.json"

    .PARAMETER Renew
        Prompts the user for a new password for an existing pair.
        To be used after a password change.
        Default value is $false

    .PARAMETER SecureString
        Saves and returns a SecureString object instead of PSCredential Object.
        Used for non Credential secrets.
        Default value is $false

    .EXAMPLE
        Enter-PsSession -ComputerName Computer -Credential (Get-SavedCredentials)
        Returns a default PsCredential object into the Enter-PsSession command.

    .EXAMPLE
        $Credential = Get-SavedCredentials -Title Normal -VaultPath c:\temp\myfile.json
        Returns a PsCredential object to to the variable $Credential

    .EXAMPLE
        $SecureString = Get-SavedCredentials -SecureString
        Returns a SecureString object to to the variable $SecureString

    .LINK
        https://github.com/gbuktenica/GetSavedCredentials

    .NOTES
        License      : MIT License
        Copyright (c): 2020 Glen Buktenica
        Release      : v1.1.0 20200318
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
    if ($Json.$Title.username.Length -eq 0 -and -not $SecureString) {
        #Prompt user for username if it is not saved.
        $Message = "Enter User name for> $Title"
        $Username = Read-Host $Message -ErrorAction Stop
        ($Json.$Title.username) = $Username
        $JsonChanged = $true
    }
    if ($Json.$Title.password.Length -eq 0 -or $Renew) {
         #Prompt user for Password if it is not saved.
        if ($SecureString) {
            $Message = "Enter Secret for> " + $Json.$Title
        }
        else {
            $Message = "Enter Password for> " + $Json.$Title.username
        }
        $Json.$Title.password = ((Read-Host $Message -AsSecureString -ErrorAction Stop))
        $JsonChanged = $true
    }
    If ($SecureString) {
        Try {
            # Build the SecureString object and export it.
            $Json.$Title.password | ConvertTo-SecureString -ErrorAction Stop
        }
        catch
        {
            # If building the SecureString failed for any reason delete it and run the function
            # again which will prompt the user for the secret.
            $TitleContent = " { `"username`":`"`", `"password`":`"`" }"
            $Json | Add-Member -Name $Title -value (Convertfrom-Json $TitleContent) -MemberType NoteProperty -Force
            $Json | ConvertTo-Json -depth 3 | Set-Content $VaultPath -ErrorAction Stop
            Get-SavedCredentials -Title $Title -VaultPath $VaultPath -SecureString
        }
    }
    else {
        $Username = $Json.$Title.username
        Try {
            # Build the PSCredential object and export it.
            $SecurePassword = $Json.$Title.password | ConvertTo-SecureString -ErrorAction Stop
            New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword -ErrorAction Stop
        }
        catch {
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
##############################
# Example Code. DO NOT COPY. #
##############################
# Remove Test Passwords
Remove-Item -path "$env:USERPROFILE\PowerShellHashTest.json" -ErrorAction SilentlyContinue
# Example PsCredential
$Credential = Get-SavedCredentials -Title Normal -VaultPath "$env:USERPROFILE\PowerShellHashTest.json"
$Credential.username

# Example PsCredential
$SecureString = Get-SavedCredentials -SecureString
$SecureString | ConvertFrom-SecureString