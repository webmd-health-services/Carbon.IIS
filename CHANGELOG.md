
# 1.0.0

## Upgrade Instructions

Replace usages of the `Install-CIisAppPool` function's `-UserName` and `-Password` arguments with the `-Credential`
parameter:

    Install-CIisAppPool -Username $username -Password $password

with

    Install-CIisAppPool -Credential ([pscredential]::New($username, $password))

All backwards-compatible function aliases removed. Rename usages of:
* `Test-IisAppPoolExists` to `Test-CIisAppPool`
* `Test-IisWebsiteExists` to `Test-CIisWebsite`
* `Remove-CIisWebsite` to `Uninstall-CIisWebsite`


## Changes

* Removed the `-UserName` and `-Password` parameters from `Install-CIisAppPool`. Use its `-Credential` parameter
instead.
* Removed aliases `Test-IisAppPoolExists` (for `Test-CIisAppPool`), `Test-IisWebsiteExists` (for `Test-CIisWebsite`),
and `Remove-CIisWebsite` (for `Uninstall-CIisWebsite`).
