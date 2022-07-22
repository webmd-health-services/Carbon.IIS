
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

Remove usages of `Carbon.Iis.HttpHeader`, `Carbon.Iis.HttpRedirectConfigurationSection`,
`Carbon.Iis.HttpResponseStatus`, and `Carbon.Iis.MimeMap` objects. They have been removed.

Update usages of return objects from the `Get-CIisHttpRedirect` function. The function no longer returns a
`Carbon.Iis.HttpResponseStatus` object and instead returns a `Microsoft.Web.Administration.ConfigurationSection`.
It no longer has `ChildOnly`, `Destination`, `Enabled`, `ExactDestination`, and `HttpResponseStatus` properties. Update
usages to use the `GetAttributeValue` method instead, e.g. `GetAttributeValue('childOnly')`, 
`GetAttributeValue('destination')`, etc. The value of `httpResponseStatus` is now returned as an int, instead of an
enumeration.

## Removed

* Removed the `-UserName` and `-Password` parameters from `Install-CIisAppPool`. Use its `-Credential` parameter
instead.
* Removed aliases `Test-IisAppPoolExists` (for `Test-CIisAppPool`), `Test-IisWebsiteExists` (for `Test-CIisWebsite`),
and `Remove-CIisWebsite` (for `Uninstall-CIisWebsite`).
* The objects returned from the `Get-CIisHttpRedirect` function changed to
`Microsoft.Web.Administration.ConfigurationSection` objects. They no longer have `ChildOnly`, `Destination`, `Enabled`, `ExactDestination`, and `HttpResponseStatus`
properties. Use `GetAttributeValue` or `SetAttributeValue` to get/set values instead.
