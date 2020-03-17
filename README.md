# Get Saved Credential

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Copyright Glen Buktenica](https://img.shields.io/badge/Copyright_(c)-2020_Glen_Buktenica-blue.svg)](http://buktenica.com)

This function returns a PSCredential from a file encrypted using Windows Data Protection API (DAPI).
If the file does not exist the user will be prompted for the username and password the first time.
The GPO setting Network Access: Do not allow storage of passwords and credentials for network authentication must be set to Disabled otherwise the password will only persist for the length of the user session.

## Example Usage

```powershell
Enter-PsSession -ComputerName Computer -Credential (Get-SavedCredentials)
```

```powershell
$Credential = Get-SavedCredentials -Title Normal -VaultPath c:\temp\MyFile.json
```
