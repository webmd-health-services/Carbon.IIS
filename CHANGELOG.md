<!--markdownlint-disable no-duplicate-heading-->

# Carbon.IIS Changelog

## 1.5.0

### Added

* `Rename-CIisAppPool` to rename IIS application pools.
* `Rename-CIisWebsite` to rename IIS websites.

### Changed

Reduced directory depth of internal, private, nested modules.

## 1.4.0

> Released 19 Mar 2024

### Added

* The `Start-CIisAppPool` function now starts the Windows Process Activation Service (WAS) if it is not running.
  Application pools fail to start if WAS isn't running.
* The `Start-CIisWebsite` function now starts the World Wide Web Publishing Service (W3SVC) if it is not running.
  Websites fail to start if W3SVC isn't running.

### Fixed

* Information message written by `Install-CIisVirtualDirectory` missing a closing quote around virtual directory's
website name.
* `Remove-CIisCollectionItem` always writes an information message even when there is nothing to delete.

## 1.3.0

> Released 14 Nov 2023

### Added

* The schema for some collection items (e.g. `system.webServer/httpErrors`) is missing unique key attribute names. Added
parameter `UniqueKeyAttributeName` to functions `Remove-CIisCollectionItem`, `Set-CIisCollection`,
`Set-CIisCollectionItem` to allow manually specifying the unique key attribute name.

### Fixed

* `Set-CIisCollection` and `Set-CIisCollectionItem` fail to operate on collections whose add element name isn't
`add`.

## 1.2.0

> Released 25 Sep 2023

### Added

* Function `Add-CIisHttpHeader` for adding HTTP headers by adding them to the
`system.webServer/httpProtocol/customHeaders` configuration collection.
* Function `Get-CIisCollection` for getting an IIS configuration collection.
* Function `Get-CIisCollectionKeyName` for getting the unique key for an IIS configuration collection.
* Function `Remove-CIisCollectionItem` for removing an item from an IIS configuration collection.
* Function `Set-CIisCollection` for setting an IIS configuration collection.
* Function `Set-CIisCollectionItem` for adding/updating items in an IIS configuration collection.
* Function `Disable-CIisCollectionInheritance` for disabling IIS configuration collections from inheriting items, i.e.
it adds the `clear` element to the collection.
* Function `Suspend-CIisAutoCommit` to stop Carbon.IIS from committing changes.
* Function `Resume-CIisAutoCommit` to start Carbon.IIS commiting changes.
* Function `Get-CIisCollectionItem` for getting the items from an IIS configuration collection.
* Function `Uninstall-CIisApplication` for deleting IIS applications.
* Function `Uninstall-CIisVirtualDirectory` for deleting virtual directories.
* Function `Remove-CIisConfigurationLocation` can now remove specific configuration sections from a location instead of
the entire location.
* Function `Remove-CIisConfigurationATtribute` can now remove attributes on any configuration element, e.g. sites,
application pools, applications, virtual directories, etc.

### Fixed

* Importing `Carbon.IIS` module requires running powershell as administrator. Without running as administrator the
module would fail to import.
* Fixed: `ConvertTo-CIisVirtualPath` fails if the virtual path contains wildcard characters.

## 1.1.0

> Released 16 Aug 2023

Added `Set-CIisWebsiteBinding` function for configuring a website's existing bindings.

## 1.0.1

> Released 16 Jun 2023

Fixed: `Install-CIisWebsite` doesn't show information messages about changes to a website's bindings if passed duplicate
bindings.

## 1.0.0

> Released 17 Feb 2023

### Upgrade Instructions

If migrating from Carbon, follow these upgrade instructions.

#### System Requirements

Upgrade to PowerShell 5.1 or PowerShell 7. PowerShell 4 is no longer supported. Microsoft's web administration API
doesn't work under PowerShell 6, so neither does Carbon.IIS.

Windows 2008 is no longer supported. Minimum operating system is Windows 8.1 and Windows Server 2012 R2.

#### Renames

Rename usages of:

* `Enable-CIisSsl` to `Enable-CIisHttps`
* `Remove-CIisWebsite` to `Uninstall-CIisWebsite`
* `Set-CIisWebsiteSslCertificate` to `Set-CIisWebsiteHttpsCertificate`
* `Test-IisAppPoolExists` to `Test-CIisAppPool`
* `Test-IisWebsiteExists` to `Test-CIisWebsite`

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
* Update usages of the `Set-CIisHttpRedirect` function to add `-Enabled $true`. The `Set-CIisHttpRedirect` function no
longer enables HTTP redirection by default.
* Update usages of the `Set-CIisHttpRedirect` function's `ExactDestination` switch to take in a `$true` or `$false`
value. The `ExactDestination` switch is now a boolean parameter. Change usages of `-ExactDestination` to
`-ExactDestination $true` and usages of `-ExactDestination:$false` to `-ExactDestination $false`.
* Update usages of the `Set-CIisHttpRedirect` function's `ChildOnly` switch to take in a `$true` or `$false` value. The
`ChildOnly` switch is now a boolean parameter. Change usages of `-ChildOnly` to `-ChildOnly $true` and usages of
 `-ChildOnly:$false` to `-ChildOnly $false`.

### Added

#### Functionality

* Tab auto-completion for parameters that accept application pool names, website names, application paths, and location
paths.
* `Get-CIIsAppPool` can now return application pool defaults settings. Use the new `AsDefaults` switch.
* `Get-CIisWebsite` can now return website defaults settings. Use the new `AsDefaults` switch.
* `Install-CIisAppPool` can now configure *all* application pool settings (i.e. all settings stored on an application
pool's `add` element in IIS' applicationHost.config file). Added parameters `QueueLength`, `AutoStart`,
`Enable32BitAppOnWin64`, `ManagedRuntimeLoader`, `EnableConfigurationOverride`, `ManagedPipelineMode`, `CLRConfigFile`,
`PassAnonymousToken`, and `StartMode` to `Install-CIisAppPool`.
* Added support for a `308` (`PermRedirect`) response code to `Set-CIisHttpRedirect`.
* `WhatIf` support to the following functions:
  * `Enable-CIisDirectoryBrowsing`
  * `Remove-CIisMimeMap`
* `Uninstall-CIisAppPool` now stops the application pool before deleting. Sometimes, the application pool remains
running even after `Uninstall-CIisAppPool` returns.

#### Functions

* `ConvertTo-CIisVirtualPath` for normalizing a virtual path (i.e. removing duplicate slashes, ensuring directory
separators are `/`, etc.).
* `Get-CIisConfigurationLocationPath` for determining if a website or website/virtual path has custom configuration
(i.e. there's a `<location>` element for it in the applicationHost.config).
* `Get-CIisVirtualDirectory` for getting virtual directories.
* `Install-CIisVirtualDirectory` can now install virtual directories under applications, not just website root. Pass the
 application name to the `ApplicationPath` parameter.
* `Join-CIisPath` function for joining virtual and location path segments into a single path.
* `Remove-CIisConfigurationAttribute` for removing attributes from configuration sections.
* `Remove-CIisConfigurationLocation` for removing a website's or website/virtual path's custom configuration (i.e.
removes its `<location>` element from applicationHost.config).
* `Restart-CIisAppPool` for stopping and starting an application pool.
* `Restart-CIisWebsite` for stopping and starting a website.
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
* `Set-CIisAppPoolRecycling` for configuring an IIS applicaiton pool's recycling settings or configuring the default
application pool recycling settings.
* `Set-CIisConfigurationAttribute` for configuring attributes on IIS configuration elements.
* `Set-CIisWebsite` for setting a website's `id` and `serverAutoStart` properties.
* `Set-CIisWebsiteLimit` for setting a website's limits (connections, bandwidth, etc.).
* `Set-CIisWebsiteLogFile` for configuring a website's log file settings and the default website log file settings.
* Many functions now write messages to PowerShell's information stream when they make configuration changes.
* `Start-CIisAppPool` for starting an application pool.
* `Start-CIisWebsite` for starting a website.
* `Stop-CIisAppPool` for stopping an application pool.
* `Stop-CIisWebsite` for stopping a website.
* `Wait-CIisAppPoolWorkerProcess` for waiting for an application pool to have a running worker process.

#### Parameters

* `Get-CIisApplication`: parameter `Defaults` for getting application default settings.
* `Get-CIisAppPool`: parameter `Defaults` for getting application pool default settings.
* `Get-CIisWebsite`: parameter `Defaults` for getting website default settings.
* `Install-CIisWebsite`: parameter `ServerAutoStart`, which configures a website's `serverAutoStart` setting.
* `Install-CIisWebsite`: parameter `Timeout`, which controls how long `Install-CIisWebsite` waits for a website to be
available before returning. The default value is 30 seconds.
* `Install-CIIsAppPool`: `Credential`, which replaces the `UserName`/`Password` parameters.
* `Set-CIisHttpRedirect`: `Enabled` to control if HTTP redirect is enabled or not.
* `Set-CIisWindowsAuthentication`:
  * `AuthPersistNonNtlm`, which sets the value of the `authPersistNonNtlm` setting.
  * `AuthPersistSingleRequest`, which sets the value of the `authPersistSingleRequest` setting.
  * `Enabled`, which sets the value of the `enabled` setting.
  * `UseAppPoolCredentials`, which sets the value for the `useAppPoolCredentials` setting.
  * `UseKernelMode`, which sets the value for the `useKernelMode` setting. (This replaces the now-obsolete
  `DisableKernelMode` parameter.)
* `Reset` switch on the following function. When set, the `Reset` switch will delete the IIS setting of each parameter
*not* passed to the functions, which resets the IIS setting to its default value. Useful for ensuring that an object
is configured *exactly* as specified in code.
  * `Set-CIisAnonymousAuthentication`
  * `Set-CIisHttpRedirect`
  * `Set-CIisWindowsAuthentication`

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
  * `Enable-CIisHttps` (née `Enable-CIisSsl`)
* `Get-CIisAppPool` now writes an error when an application pool does not exist. Add `-ErrorAction Ignore` or
`-ErrorAction SilentlyContinue` to hide the error.
* `Get-CIisAppPool` now supports wildcards in values of its `Name` parameter.
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
* The `Set-CIisAnonymousAuthentication` function's `Enabled` switch is now a parameter. Pass `$true` to enable anonymous
authentication or `$false` to disable it.
* The `Set-CIisHttpRedirect` function's `ExactDestination` and `ChildOnly` switches are now boolean parameters. Pass
`$true` to enable or `$false` to disable.
* The `Set-CIisHttpRedirect` function's `HttpResponseStatus` parameter is now an enumeration value so you don't have to
remember redirect code numbers.

### Deprecated

* The `SiteName` and `VirtualPath` (which has a `Path` alias) parameter on the following functions. Use the
`LocationPath` parameter instead and pass the site name and virtual path as a single location path, separated by a `/`,
e.g. `SiteName/VirtualPath`.
  * `Add-CIisDefaultDocument`
  * `Disable-CIisSecurityAuthentication`
  * `Enable-CIisDirectoryBrowsing`
  * `Enable-CIisSecurityAuthentication`
  * `Enable-CIisHttps` (née `Enable-CIisSSl`)
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
* The `Join-CIisVirtualPath` function. Use the `Join-CIisPath` function instead.
* The `Set-CIisWebsiteID` function. Use `Set-CIisWebsite` instead.
* The `Set-CIisWindowsAuthentication` function's `DisableKernelMode` switch. Use the new `UseKernelMode` parameter
instead.

### Fixed

* `Install-CIisWebsite` wouldn't save changes when an existing website doesn't define its default application.
* `Set-CIisWebsiteHttpsCertificate` (née `Set-CIisWebsiteSslCertificate`) would fail if passed `Ignore` as an error
action.

### Renamed

* `Enable-CIisSsl` to `Enable-CIisHttps`
* `Remove-CIisWebsite` to `Uninstall-CIisWebsite`
* `Set-CIisWebsiteSslCertificate` to `Set-CIisWebsiteHttpsCertificate`

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
