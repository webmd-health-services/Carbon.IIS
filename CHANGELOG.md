
# 1.0.0

## Upgrade Instructions

If migrating from Carbon, follow these upgrade instructions.

Upgrade to PowerShell 5.1 or PowerShell 7. PowerShell 4 is no longer supported. Microsoft's web administration API
doesn't work under PowerShell 6, so neither does Carbon.IIS.

Windows 2008 is no longer supported. Minimum operating system is Windows 8.1 and Windows Server 2012 R2.

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

Removed the `Path` parameter alias on the `Install-CIisApplication` function. Update usages to `PhysicalPath`.

Renamed the `VirtualPath` parameter to `Path` on the `Get-CIisApplication` and `Install-CIisApplication` functions.
Update usages.

Removed the `Name` paramater aliases. Update usages of the `Name` parameter on these functions to `Path`:
* Get-CIisApplication
* Install-CIisApplication

`Get-CIisAppPool` now writes an error when passed a name and an application pool with that name does not exist. Update
usages with `-ErrorAction Ignore` to preserve previous behavior.

Objects returned by `Get-CIisApplication`, and `Get-CIisAppPool` no longer have a `CommitChanges`
method or a `ServerManager` member. Updates usages to call the new `Save-CIisConfiguration` function.

Removed function `Set-CIisWebsiteID`. Replace usages of `Set-CIisWebsiteID` with `Set-CIisWebsite`.

### Get-CIisWebsite

* Removed `SiteName` parameter alias. Rename usages of the `SiteName` parameter to `Name`.
* Now writes an error if a specific website doesn't exist. If a usage doesn't care if the website exists or not, add
`-ErrorAction SilentlyContinue` or `-ErrorAction Ignore`.
* Returned site objects no longer have a `CommitChanges` method or a `ServerManager` method. Updates usages to call the
new `Save-IisConfiguration` function.

### Install-CIisWebsite

* No longer sets the default anonymous authentication username on a website to nothing. New websites will now use the
IIS default value. To preserve the previous behavior, use the `Set-CIisAnonymousAuthentication` function.
* Removed `SiteName` parameter alias. Rename usages of the `SiteName` parameter to `Name`.
* Rename usages of parameter `SiteID` to `ID`.
* Remove usages of the `-Force` switch. To implement its functionality, add `Uninstall-CIisWebsite` to code before
calling `Install-CIisWebsite`.

### Install-CIisAppPool

* Removed the `IdleTimeout`, `ServiceUser`, and `Credential`. These are process model settings. Update usages to use the
new `Set-CIisAppPoolProcessModel` function to configure these settings.
* Replace usages of switch `-Enable32BitApps` with parameter `-Enable32BitAppOnWin64 $true`.
* Replace usages of `ClassicPipelineMode` with `-ManagedPipelineMode Classic`.
* The managed pipeline mode is no longer set by default. Add `-ManagedPipelineMode Integrated` to all usages of
`Install-CIisAppPool` where the default might be `Classic`.
* The managed runtime version is no longer set by default. Add `-ManagedRuntimeVersion 'v4.0'` to all usages of
`Install-CIisAppPool`.

## Added

* Carbon.IIS now supports
    * Windows PowerShell 5.1 (on .NET Framework 4.6.2 and later) and PowerShell 7
    * Windows 8 and 10, and Windows Server 2012R2, 2016, and 2019.
* Function `Set-CIisConfigurationAttribute` for configuring attributes on IIS configuration elements
* Function `Set-CIisAnonymousAuthentication` for configuring anonymous authentication.
* Function `Remove-CIisConfigurationAttribute` for removing attributes from configuration sections.
* Function `ConvertTo-CIisVirtualPath` for normalizing a virtual path (i.e. removing duplicate slashes, ensuring
directory separators are `/`, etc.).
* Function `Install-CIisVirtualDirectory` can now install virtual directories under applications, not just website root.
Pass the application name to the `ApplicationPath` parameter.
* Function `Get-CIisConfigurationLocationPath` for determining if a website or website/virtual path has custom
configuration (i.e. there's a `<location>` element for it in the applicationHost.config).
* Function `Remove-CIisConfigurationLocation` for removing a website's or website/virtual path's custom configuration
(i.e. removes its `<location>` element from applicationHost.config).
* Many functions now write messages to PowerShell's information stream when they make configuration changes.
* Function `Set-CIisAppPoolCpu` for configuring an application pool's CPU settings and the application pool defaults
CPU settings.
* Function `Save-CIisConfiguration` for saving configuration changes to IIS. Only needed if you make changes to any of
the objects returned by the Carbon.IIS module.
* Function `Set-CIisWebsiteLogFile` for configuring a website's log file settings and the website defaults log file
settings.
* Function `Set-CIisAppPoolPeriodicRestart` for configuring an application pool's periodic restart settings and
the application pool defaults periodic restart settings.
* `Get-CIIsAppPool` and `Get-CIisWebsite` can now return the application pool defaults and the website
defaults settings, respectively. Use the new `AsDefaults` switch.
* Function `Set-CIisAppPoolProcessModel` for configuring an IIS application pool's process model or configuring the
application pool defaults process model.
* `Install-CIisAppPool` can now configure *all* application pool settings (i.e. all settings stored on an application
pool's `add` element in IIS' applicationHost.config file). Added parameters `QueueLength`, `AutoStart`,
`Enable32BitAppOnWin64`, `ManagedRuntimeLoader`, `EnableConfigurationOverride`, `ManagedPipelineMode`, `CLRConfigFile`,
`PassAnonymousToken`, and `StartMode` to `Install-CIisAppPool`.
* Function `Set-CIisWebsite`, for setting a website's `id` and `serverAutoStart` properties.
* Parameter `ServerAutoStart` to `Install-CIisWebsite` which configures a website's `serverAutoStart` setting.

## Changes

* `Get-CIisWebsite` now writes an error if a specific website doesn't exist.
* The `Join-CIisVirtualPath` function's `ChildPath` parameter is now required. Usages that don't have a `ChildPath`
argument should switch to `ConvertTo-CIisVirtualPath`.
* Renamed `VirtualPath` parameter on `Get-CIisApplication` and `Install-CIisApplication` to `Path`.
* `Get-CIisAppPool` now writes an error when passed a name and an application pool with that name does not exist.
* The managed pipeline mode is no longer set by default by `Install-CIisAppPool`.
* The managed runtime version is no longer set by default by `Install-CIisAppPool`.

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
* Objects returned by `Get-CIisWebsite`, `Get-CIisApplication`, and `Get-CIisAppPool` no longer have a `CommitChanges()`
method or a `ServerManager` property. Use the new `Save-CIisConfiguration` function to save changes you make to objects
returned by any Carbon.IIS function.
* The `Install-CIisAppPool` function's `IdleTimeout`, `ServiceAccount`, and `Credential` parameters. Use the new
`Set-CIisAppPoolProcessModel` function to configure an application pool's process model.
* The `Install-CIisAppPool` function's `Enable32BitApps` switch replaced with parameter `Enable32BitAppOnWin64`.
* The `Install-CIisAppPool` function's `ClassicPipelineMode` switch. Replaced by parameter `ManagedPipelineMode`, which
allows values `Classic` or `Integrated`.
* The `Install-CIisAppPool` function's `Enable32BitApps` switch replaced with the `Enable32BitAppOnWin64` parameter.
* Function `Set-CIisWebsiteID`. Use `Set-CIisWebsite` instead.
