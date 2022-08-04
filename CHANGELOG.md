
# 1.0.0

## Upgrade Instructions

If migrating from Carbon, follow these upgrade instructions.

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

The `Install-CIisWebsite` function no longer sets the default anonymous authentication username on a website to nothing.
New websites will now have the default anonymous authentication username of `IUSR`. To preserve the previous behavior,
use the `Set-CIisAnonymousAuthentication`.

Upgrade to PowerShell 5.1 or PowerShell 7. PowerShell 4 is no longer supported. Microsoft's web administration API
doesn't work under PowerShell 6, so neither does Carbon.IIS.

Windows 2008 is no longer supported. Minimum operating system is Windows 8.1 and Windows Server 2012 R2.

## Added

* Carbon.IIS now supports
    * Windows PowerShell 5.1 (on .NET Framework 4.6.2 and later) and PowerShell 7
    * Windows 8 and 10, and Windows Server 2012R2, 2016, and 2019.
* Function `Set-CIisAnonymousAuthentication` for configuring anonymous authentication.
* Function `Remove-CIisConfigurationAttribute` for removing attributes from configuration sections.

## Fixed

* `Install-CIisWebsite` wouldn't save changes when an existing website doesn't define its default application.

## Removed

* Carbon.IIS no longer works under PowerShell 4. Minimum PowerShell version is 5.1.
* Removed the `-UserName` and `-Password` parameters from `Install-CIisAppPool`. Use its `-Credential` parameter
instead.
* Removed aliases `Test-IisAppPoolExists` (for `Test-CIisAppPool`), `Test-IisWebsiteExists` (for `Test-CIisWebsite`),
and `Remove-CIisWebsite` (for `Uninstall-CIisWebsite`).
* The objects returned from the `Get-CIisHttpRedirect` function changed to
`Microsoft.Web.Administration.ConfigurationSection` objects. They no longer have `ChildOnly`, `Destination`, `Enabled`, `ExactDestination`, and `HttpResponseStatus`
properties. Use `GetAttributeValue` or `SetAttributeValue` to get/set values instead.
