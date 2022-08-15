
# 1.0.0

## Upgrade Instructions

If migrating from Carbon, follow these upgrade instructions.

Upgrade to PowerShell 5.1 or PowerShell 7. PowerShell 4 is no longer supported. Microsoft's web administration API
doesn't work under PowerShell 6, so neither does Carbon.IIS.

Windows 2008 is no longer supported. Minimum operating system is Windows 8.1 and Windows Server 2012 R2.

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

The `Install-CIisWebsite` function no longer sets the default anonymous authentication username on a website to
nothing. New websites will now have the default anonymous authentication username of `IUSR`. To preserve the previous
behavior, use the `Set-CIisAnonymousAuthentication`.

`Get-CIisWebsite` now writes an error if a specific website doesn't exist. If a usage doesn't care if the website
exists or not, add `-ErrorAction SilentlyContinue` or `-ErrorAction Ignore`.

The `Join-CIisVirtualPath` function's `ChildPath` parameter is now mandatory. If you have usages without a `ChildPath`
parameter, switch to using the new `ConvertTo-CIisVirtualPath`.

The `Install-CIisVirtualDirectory` function's `VirtualPath` parameter was renamed to `Path`. Please update usages.

Removed the `Install-CIisVirtualDirectory` function's `Path` parameter alias to the `PhysicalPath` parameter. Update
usages.

Removed `Path` parameter aliases. Update usages of the `Path` parameter on these functions to `VirtualPath`:
* Disable-CIisSecurityAuthentication
* Enable-CIisSecurityAuthentication
* Enable-CIisSecurityAuthentication
* Enable-CIisSsl
* Get-CIisConfigurationSection
* Get-CIisHttpHeader
* Get-CIisHttpRedirect
* Get-CIisMimeMap
* Get-CIisSecurityAuthentication
* Set-CIisHttpHeader
* Set-CIisHttpRedirect
* Set-CIisWindowsAuthentication
* Test-CIisConfigurationSection
* Test-CIisSecurityAuthentication

Removed `SiteName` parameter aliases. Update usages of the `SiteName` parameter on these functions to `Name`:
* Get-CIisWebsite
* Install-CIisWebsite

Removed the `Path` parameter alias on the `Install-CIisApplication` function. Update usages to `PhysicalPath`.

Renamed the `VirtualPath` parameter to `Path` on the `Get-CIisApplication` and `Install-CIisApplication` functions.
Update usages.

Removed the `Name` paramater aliases. Update usages of the `Name` parameter on these functions to `Path`:
* Get-CIisApplication
* Install-CIisApplication


## Added

* Carbon.IIS now supports
    * Windows PowerShell 5.1 (on .NET Framework 4.6.2 and later) and PowerShell 7
    * Windows 8 and 10, and Windows Server 2012R2, 2016, and 2019.
* Function `Set-CIisAnonymousAuthentication` for configuring anonymous authentication.
* Function `Remove-CIisConfigurationAttribute` for removing attributes from configuration sections.
* Function `ConvertTo-CIisVirtualPath` for normalizing a virtual path (i.e. removing duplicate slashes, ensuring
directory separators are `/`, etc.).
* Function `Install-CIisVirtualDirectory` can now install virtual directories under applications, not just website root.
Pass the application name to the `ApplicationPath` parameter.

## Changes

* `Get-CIisWebsite` now writes an error if a specific website doesn't exist.
* The `Join-CIisVirtualPath` function's `ChildPath` parameter is now required. Usages that don't have a `ChildPath`
argument should switch to `ConvertTo-CIisVirtualPath`.
* Renamed `VirtualPath` parameter on `Get-CIisApplication` and `Install-CIisApplication` to `Path`.

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
* `Path` parameter alias on functions
    * Disable-CIisSecurityAuthentication
    * Enable-CIisSecurityAuthentication
    * Enable-CIisSecurityAuthentication
    * Enable-CIisSsl
    * Get-CIisApplication
    * Get-CIisConfigurationSection
    * Get-CIisHttpHeader
    * Get-CIisHttpRedirect
    * Get-CIisMimeMap
    * Get-CIisSecurityAuthentication
    * Install-CIisApplication
    * Set-CIisHttpHeader
    * Set-CIisHttpRedirect
    * Set-CIisWindowsAuthentication
    * Test-CIisConfigurationSection
    * Test-CIisSecurityAuthentication
* `SiteName` parameter alias on functions:
    * Get-CIisWebsite
    * Install-CIisWebsite
* `Path` parameter alias to `PhysicalPath` on function `Install-CIisApplication`.
* `Name` parameter alias on functions:
    * Get-CIisApplication
    * Install-CIisApplication

