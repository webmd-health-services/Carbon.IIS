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
* the `Install-CIisVirtualDirectory` function's `Path` parameter to `PhysicalPath` parameter. Then, rename usages of the `Install-CIisVirtualDirectory` function's `VirtualPath` parameter to `Path`.
* the `Path` parameter on these functions to `VirtualPath`:
  * `Disable-CIisSecurityAuthentication`
  * `Enable-CIisSecurityAuthentication`
  * `Enable-CIisSecurityAuthentication`
  * `Enable-CIisSsl`
  * `Get-CIisConfigurationSection`
  * `Get-CIisHttpHeader`
  * `Get-CIisHttpRedirect`
  * `Get-CIisMimeMap`
  * `Get-CIisSecurityAuthentication`
  * `Set-CIisHttpHeader`
  * `Set-CIisHttpRedirect`
  * `Set-CIisWindowsAuthentication`
  * `Test-CIisConfigurationSection`
  * `Test-CIisSecurityAuthentication`
* the `Install-CIisApplication` function's `Path` parameter to `PhysicalPath`.
* the `Get-CIisApplication` and `Install-CIisApplication` functions' `VirtualPath` parameter to `Path`.
* the `Name` parameter on these functions to `Path`:
  * `Get-CIisApplication`
  * `Install-CIisApplication`
* the following functions' `SiteName` parameter to `Name`:
  * `Install-CIisWebsite`
* the `Install-CIisWebsite` function's `SiteID` parameter to `ID`.

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
* Replace usages of the `Join-CIisVirtualPath` function that doesn't use the `ChildPath` parameter to use the new
`ConvertTo-CIisVirtualPath` function. The `Join-CIisVirtualPath` function's `ChildPath` parameter is now mandatory.
* Add `-ErrorAction Ignore` or `-ErrorAction SilentlyContinue` to usages of the following functions. They now write errors
when an item doesn't exist.
  * `Get-CIisAppPool`
  * `Get-CIisWebsite`
* Replace usages of the `CommitChanges` method on objects returned by any Carbon.IIS function with a call to the new
`Save-CIisConfiguration` function. Objects returned by Carbon.IIS no longer have a `CommitChanges` method.
* Replace usages of `Set-CIisWebsiteID` with `Set-CIisWebsite`.
* Add a call to `Set-CIisAnonymousAuthentication` after usages of `Install-CIisWebsite`. The `Install-CIisWebsite` no
longer sets the default anonymous authentication username on a website to nothing.
* Add a call to `Uninstall-CIisWebsite` before calls to `Install-CIisWebsite` and remove usages of the
`Install-CIisWebsite` function's `-Force` switch. The `Install-CIisWebsite` function no longer deletes a website before
installing it.
* `Install-CIisAppPool`:
  * Remove usages of the `IdleTimeout`, `ServiceUser`, and `Credential` parameters and move them to a call
  to the new `Set-CIisAppPoolProcessModel` function (which should come *after* `Install-CIisAppPool`).
  * Replace usages of the `-Enable32BitApps` switch with `-Enable32BitAppOnWin64 $true`.
  * Replace usages of the `-ClassicPipelineMode` switch with `-ManagedPipelineMode Classic`.
  * Add `-ManagedPipelineMode Integrated` to all usages of `Install-CIisAppPool` that don't use the
  `ManagedPipelineMode` (née `ClassicPipelineMode`) parameter. The `Install-CIisAppPool` function no longer sets the
  pipeline mode of an app pool if the `ManagedPipelineMode` parameter isn't provided.
  * Add `-ManagedRuntimeVersion 'v4.0'` to all usages of `Install-CIisAppPool` that doesn't use the
  `-MangedRuntimeVersion` parameter. The `Install-CIisAppPool` function no longer sets the managed runtime version if
  that parameter isn't provided.
* The `Install-CIIsAppPool` and `Install-CIisWebsite` functions

### Added

#### Functionality

* `Get-CIIsAppPool` can now return application pool defaults settings. Use the new `AsDefaults` switch.
* `Get-CIisWebsite` can now return website defaults settings. Use the new `AsDefaults` switch.
* `Install-CIisAppPool` can now configure *all* application pool settings (i.e. all settings stored on an application
pool's `add` element in IIS' applicationHost.config file). Added parameters `QueueLength`, `AutoStart`,
`Enable32BitAppOnWin64`, `ManagedRuntimeLoader`, `EnableConfigurationOverride`, `ManagedPipelineMode`, `CLRConfigFile`,
`PassAnonymousToken`, and `StartMode` to `Install-CIisAppPool`.

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
* `Set-CIisAppPool` for configuring an application pool's base settings.
* `Set-CIisAppPoolCpu` for configuring an application pool's CPU settings and the application pool defaults CPU
settings.
* `Set-CIisAppPoolPeriodicRestart` for configuring an application pool's periodic restart settings and the application
pool defaults periodic restart settings.
* `Set-CIisAppPoolProcessModel` for configuring an IIS application pool's process model or configuring the application
pool defaults process model.
* `Set-CIisConfigurationAttribute` for configuring attributes on IIS configuration elements
* `Set-CIisWebsite`, for setting a website's `id` and `serverAutoStart` properties.
* `Set-CIisWebsiteLogFile` for configuring a website's log file settings and the website defaults log file settings.
* Many functions now write messages to PowerShell's information stream when they make configuration changes.

#### Parameters

* `Install-CIisWebsite`: parameter `ServerAutoStart`, which configures a website's `serverAutoStart` setting.
* `Install-CIIsAppPool`: `Credential`, which replaces the `UserName`/`Password` parameters.

### Changed

* Carbon.IIS now supports
  * Windows PowerShell 5.1 (on .NET Framework 4.6.2 and later) and PowerShell 7
  * Windows 8 and 10, and Windows Server 2012R2, 2016, and 2019.
* Renamed `VirtualPath` parameter on `Get-CIisApplication` and `Install-CIisApplication` to `Path`.
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

### Fixed

* `Install-CIisWebsite` wouldn't save changes when an existing website doesn't define its default application.
* `Set-CIisWebsiteSslCertificate` would fail if passed `Ignore` as an error action.

### Removed

#### System Requirements

* Support for PowerShell 4. Minimum PowerShell version is 5.1.
* Support for Windows 2008.

#### Parameters

* `Install-CIisAppPool`: `-UserName` and `-Password`. Use the new `-Credential` parameter instead.
* The `Install-CIisAppPool` function's `IdleTimeout`, `ServiceAccount`, and `Credential` parameters. Use the new
`Set-CIisAppPoolProcessModel` function to configure an application pool's process model.

#### Aliases

##### Function Aliases

* `Test-IisAppPoolExists` (use `Test-CIisAppPool` instead)
* `Test-IisWebsiteExists` (use `Test-CIisWebsite` instead)
* `Remove-CIisWebsite` (use `Uninstall-CIisWebsite` instead)

##### Parameter Aliases

* `Path` on these functions (use the `VirtualPath` parameter instead):
  * `Disable-CIisSecurityAuthentication`
  * `Enable-CIisSecurityAuthentication`
  * `Enable-CIisSecurityAuthentication`
  * `Enable-CIisSsl`
  * `Get-CIisApplication`
  * `Get-CIisConfigurationSection`
  * `Get-CIisHttpHeader`
  * `Get-CIisHttpRedirect`
  * `Get-CIisMimeMap`
  * `Get-CIisSecurityAuthentication`
  * `Set-CIisHttpHeader`
  * `Set-CIisHttpRedirect`
  * `Set-CIisWindowsAuthentication`
  * `Test-CIisConfigurationSection`
  * `Test-CIisSecurityAuthentication`
* `Path` on function `Install-CIisApplication` (use the `PhysicalPath` parameter instead).
* `SiteName` on these functions (use the `Name` parameter instead):
  * `Get-CIisWebsite`
  * `Install-CIisWebsite`
* `Name` on these functions (use the `VirtualPath` parameter instead):
  * `Get-CIisApplication`
  * `Install-CIisApplication`

#### Members

* The `CommitChanges()` method and `ServerManager` property on objects returned by many Carbon.IIS functions. Use the
new `Save-CIisConfiguration` function to save changes you make to objects returned by any Carbon.IIS function.
* The `Install-CIisAppPool` function's `Enable32BitApps` switch replaced with parameter `Enable32BitAppOnWin64`, which
should be `$true` or `$false`.
* The `Install-CIisAppPool` function's `ClassicPipelineMode` switch. Replaced by parameter `ManagedPipelineMode`, which
allows values `Classic` or `Integrated`.
* Function `Set-CIisWebsiteID`. Use `Set-CIisWebsite` instead.
