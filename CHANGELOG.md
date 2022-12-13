<!-- markdownlint-disable no-duplicate-heading -->

# Carbon.IIS Changelog

## 1.0.0

### Upgrade Instructions

If migrating from Carbon, follow these upgrade instructions.

#### System Requirements

Upgrade to PowerShell 5.1 or PowerShell 7. PowerShell 4 is no longer supported. Microsoft's web administration API
doesn't work under PowerShell 6, so neither does Carbon.IIS.

Windows 2008 is no longer supported. Minimum operating system is Windows 8.1 and Windows Server 2012 R2.

#### Renames

Rename usages of:

* `Test-IisAppPoolExists` to `Test-CIisAppPool`
* `Test-IisWebsiteExists` to `Test-CIisWebsite`
* `Remove-CIisWebsite` to `Uninstall-CIisWebsite`

#### Removals

* Remove usages of objects `Carbon.Iis.HttpHeader`, `Carbon.Iis.HttpRedirectConfigurationSection`,
`Carbon.Iis.HttpResponseStatus`, and `Carbon.Iis.MimeMap`. They have been removed.
* Remove usages of the `ServerManager` property objects returned by any Carbon.IIS function. Objects returned by
Carbon.IIS no longer have a `CommitChanges` method.

#### Changes

* Update usages of return objects from the `Get-CIisHttpRedirect` function. The function no longer returns a
`Carbon.Iis.HttpResponseStatus` object and instead returns a `Microsoft.Web.Administration.ConfigurationSection`.
It no longer has `ChildOnly`, `Destination`, `Enabled`, `ExactDestination`, and `HttpResponseStatus` properties. Update
usages to use the `GetAttributeValue` method instead, e.g. `GetAttributeValue('childOnly')`,
`GetAttributeValue('destination')`, etc. The value of `httpResponseStatus` is now returned as an int, instead of an
enumeration.
* Remove usages of the `Install-CIisAppPool` function's `UserName` and `Password` parameters and instead use
`Set-CIisAppPoolProcessModel` to configure an application pool's identity.
* Replace usages of the `Join-CIisVirtualPath` function that doesn't use the `ChildPath` parameter to use the new
`ConvertTo-CIisVirtualPath` function. The `Join-CIisVirtualPath` function's `ChildPath` parameter is now mandatory.
* Add `-ErrorAction Ignore` or `-ErrorAction SilentlyContinue` to usages of the following functions. They now write
errors when an item doesn't exist.
  * `Get-CIisAppPool`
  * `Get-CIisWebsite`
* Replace usages of the `CommitChanges` method on objects returned by any Carbon.IIS function with a call to the new
`Save-CIisConfiguration` function. Objects returned by Carbon.IIS no longer have a `CommitChanges` method.
* Add a call to `Set-CIisAnonymousAuthentication` after usages of `Install-CIisWebsite`. The `Install-CIisWebsite` no
longer sets the default anonymous authentication username to nothing on a website.
* Add a call to `Uninstall-CIisWebsite` before calls to `Install-CIisWebsite` and remove usages of the
`Install-CIisWebsite` function's `-Force` switch. The `Install-CIisWebsite` function no longer deletes a website before
installing it.
* Update usages of the `Set-CIisAnonymousAuthentication` function's `Enabled` switch to take in a `$true` or `$false`
value. The `Enabled` switch is now a boolean parameter. Change usages of `-Enabled` to `-Enabled $true` and
usages of `-Enabled:$false` to `-Enabled $false`.
* Update usages of the `Set-CIisHttpRedirect` function's `ExactDestination` switch to take in a `$true` or `$false`
value. The `ExactDestination` switch is now a boolean parameter. Change usages of `-ExactDestination` to
`-ExactDestination $true` and usages of `-ExactDestination:$false` to `-ExactDestination $false`.
* Update usages of the `Set-CIisHttpRedirect` function's `ChildOnly` switch to take in a `$true` or `$false` value. The
`ChildOnly` switch is now a boolean parameter. Change usages of `-ChildOnly` to `-ChildOnly $true` and usages of
 `-ChildOnly:$false` to `-ChildOnly $false`.

### Added

#### Functionality

* `Get-CIIsAppPool` can now return application pool defaults settings. Use the new `AsDefaults` switch.
* `Get-CIisWebsite` can now return website defaults settings. Use the new `AsDefaults` switch.
* `Install-CIisAppPool` can now configure *all* application pool settings (i.e. all settings stored on an application
pool's `add` element in IIS' applicationHost.config file). Added parameters `QueueLength`, `AutoStart`,
`Enable32BitAppOnWin64`, `ManagedRuntimeLoader`, `EnableConfigurationOverride`, `ManagedPipelineMode`, `CLRConfigFile`,
`PassAnonymousToken`, and `StartMode` to `Install-CIisAppPool`.
* `WhatIf` support to the following functions:
  * `Enable-CIisDirectoryBrowsing`
  * `Remove-CIisMimeMap`

#### Functions

* `ConvertTo-CIisVirtualPath` for normalizing a virtual path (i.e. removing duplicate slashes, ensuring directory
separators are `/`, etc.).
* `Get-CIisConfigurationLocationPath` for determining if a website or website/virtual path has custom configuration
(i.e. there's a `<location>` element for it in the applicationHost.config).
* `Install-CIisVirtualDirectory` can now install virtual directories under applications, not just website root. Pass the
 application name to the `ApplicationPath` parameter.
* `Remove-CIisConfigurationAttribute` for removing attributes from configuration sections.
* `Remove-CIisConfigurationLocation` for removing a website's or website/virtual path's custom configuration (i.e.
removes its `<location>` element from applicationHost.config).
* `Save-CIisConfiguration` for saving configuration changes to IIS. Only needed if you make changes to any of the
objects returned by the Carbon.IIS module.
* `Set-CIisAnonymousAuthentication` for configuring anonymous authentication.
* `Set-CIisAppPool` for configuring an application pool's settings.
* `Set-CIisAppPoolCpu` for configuring an application pool's CPU settings and the default application pool CPU
settings.
* `Set-CIisAppPoolPeriodicRestart` for configuring an application pool's periodic restart settings and the default
application pool periodic restart settings.
* `Set-CIisAppPoolProcessModel` for configuring an IIS application pool's process model or configuring the default
application pool process model.
* `Set-CIisConfigurationAttribute` for configuring attributes on IIS configuration elements.
* `Set-CIisWebsite` for setting a website's `id` and `serverAutoStart` properties.
* `Set-CIisWebsiteLogFile` for configuring a website's log file settings and the default website log file settings.
* Many functions now write messages to PowerShell's information stream when they make configuration changes.

#### Parameters

* `Install-CIisWebsite`: parameter `ServerAutoStart`, which configures a website's `serverAutoStart` setting.
* `Install-CIIsAppPool`: `Credential`, which replaces the `UserName`/`Password` parameters.
* `Set-CIisWindowsAuthentication`: parameter `UseKernelMode` for configuring the Windows authentication "useKernelMode"
setting.
* `Reset` switch on the following function. When set, the `Reset` switch will delete the IIS setting of each parameter
*not* passed to the functions, which resets the IIS setting to its default value. Useful for ensuring that an object
is configured *exactly* as specified in code.

### Changed

* Carbon.IIS now supports
  * Windows PowerShell 5.1 (on .NET Framework 4.6.2 and later) and PowerShell 7
  * Windows 8 and 10, and Windows Server 2012R2, 2016, and 2019.
* Renamed `VirtualPath` parameter on `Get-CIisApplication` and `Install-CIisApplication` to `Path`.
* Replaced the `SiteName` and `VirtualPath` parameters with a single `LocationPath` parameter on the following
functions. The value of the `LocationPath` parameter should be the website name and virtual path combined with a `/`.
  * `Add-CIisDefaultDocument`
  * `Disable-CIisSecurityAuthentication`
  * `Enable-CIisDirectoryBrowsing`
  * `Enable-CIisSecurityAuthentication`
  * `Enable-CIIsSsl`
* `Get-CIisAppPool` now writes an error when an application pool does not exist. Add `-ErrorAction Ignore` or
`-ErrorAction SilentlyContinue` to hide the error.
* `Get-CIisHttpRedirect` now returns `Microsoft.Web.Administration.ConfigurationSection` objects (instead of a custom
object), which don't longer have `ChildOnly`, `Destination`, `Enabled`, `ExactDestination`, and `HttpResponseStatus`.
* `Get-CIisWebsite` now writes an error if a specific website doesn't exist.
* `Install-CIisAppPool` no longer sets the managed pipeline mode to `Integrated`. Use the `-ManagedPipelineMode`
parameter to explicitly set the managed pipeline mode.
* `Install-CIisAppPool` no longer sets the managed runtime version to `v4.0`. Use the `-ManagedRuntimeVersion` parameter
to set the managed runtime.
* `Install-CIisAppPool` now clears *all* application pool settings that aren't passed as parameters, which resets those
settings to their default values.
* `Install-CIisWebsite` now clears *all* website settings that aren't passed as parameters, which resets those settings
to their default values.
* The `Join-CIisVirtualPath` function's `ChildPath` parameter is now required. Usages that don't have a `ChildPath`
argument should switch to `ConvertTo-CIisVirtualPath`.
* The `Set-CIisAnonymousAuthentication` function's `Enabled` switch is now a parameter. Pass `$true` to enable anonymous
authentication or `$false` to disable it.
* The `Set-CIisHttpRedirect` function's `ExactDestination` and `ChildOnly` switches are now boolean parameters. Pass
`$true` to enable or `$false` to disable.

### Deprecated

* The `SiteName` and `VirtualPath` (which has a `Path` alias) parameter on the following functions. Use the
`LocationPath` parameter instead and pass the site name and virtual path as a single location path, separated by a `/`,
e.g. `SiteName/VirtualPath`.
  * `Add-CIisDefaultDocument`
  * `Disable-CIisSecurityAuthentication`
  * `Enable-CIisDirectoryBrowsing`
  * `Enable-CIisSecurityAuthentication`
  * `Enable-CIisSsl`
  * `Get-CIisConfigurationSection`
  * `Get-CIisHttpHeader`
  * `Get-CIisHttpRedirect`
  * `Get-CIisMimeMap`
  * `Get-CIisSecurityAuthentication`
  * `Remove-CIisConfigurationLocation`
  * `Remove-CIisMimeMap`
  * `Set-CIisAnonymousAuthentication`
  * `Set-CIisConfigurationAttribute`
  * `Set-CIisHttpHeader`
  * `Set-CIisHttpRedirect`
  * `Set-CIisMimeMap`
  * `Set-CIisWindowsAuthentication`
  * `Test-CIisConfigurationSection`
  * `Test-CIisSecurityAuthentication`
* The `Get-CIisApplication` function's `Name` parameter. Use the `VirtualPath` parameter instead.
* The `Install-CIisApplication` function's `Name` parameter. Use the `VirtualPath` parameter instead.
* The `Install-CIisApplication` function's `Path` parameter. Use the `PhysicalPath` parameter instead.
* The `Install-CIisAppPool` function:
  * The `IdleTimeout`, `ServiceUser`, and `Credential` parameters. Use the `Set-CIisAppPoolProcessModel` function and
  its `IdleTimeout`, `IdentityType`, `UserName`, and `Password` parameters instead.
  * The `-Enable32BitApps` switch. Use the `-Enable32BitAppOnWin64` parameter instead.
  * The `-ClassicPipelineMode` switch. Use `-ManagedPipelineMode Classic` instead.
  * Setting the managed pipeline mode to `Integrated` by default. Use the `ManagedPipelineMode` parameter to set the
  pipeline mode.
  * Setting the managed .NET runtime version to `v4.0` by default. Use the `ManagedRuntimeVersion` parameter to set the
  pipeline mode.
* The `Install-CIisVirtualDirectory` function's `Name` parameter. Use the `VirtualPath` parameter instead.
* The `Install-CIisVirtualDirectory` function's `Path` parameter. Use the `PhysicalPath` parameter instead.
* The `Install-CIisWebsite` function's `SiteID` parameter. Use the `ID` parameter instead.
* The `Set-CIisWebsiteID` function. Use `Set-CIisWebsite` instead.
* The `Set-CIisWindowsAuthentication` function's `DisableKernelMode` switch. Use the new `UseKernelMode` parameter
instead.

### Fixed

* `Install-CIisWebsite` wouldn't save changes when an existing website doesn't define its default application.
* `Set-CIisWebsiteSslCertificate` would fail if passed `Ignore` as an error action.

### Removed

#### System Requirements

* Support for PowerShell 4. Minimum PowerShell version is 5.1.
* Support for Windows 2008.

#### Parameters

* `Install-CIisAppPool`: `UserName` and `Password`. Use the `Set-CIisAppPoolProcessModel` function instead, which
also has `UserName` and `Password` parameters.

#### Aliases

##### Function Aliases

* `Test-IisAppPoolExists` (use `Test-CIisAppPool` instead)
* `Test-IisWebsiteExists` (use `Test-CIisWebsite` instead)
* `Remove-CIisWebsite` (use `Uninstall-CIisWebsite` instead)

#### Members

* The `CommitChanges()` method and `ServerManager` property on objects returned by many Carbon.IIS functions. Use the
new `Save-CIisConfiguration` function to save changes you make to objects returned by any Carbon.IIS function.
