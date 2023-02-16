# Overview

The "Carbon.IIS" module is a module for installing and managing IIS app pools, websites, applications, and configuring
other parts of IIS.

# System Requirements

* Windows PowerShell 5.1 and .NET 4.6.2+
* PowerShell 7+
* Windows 8 and 10
* Windows Server 2012R2, 2016, and 2019

# Installing

To install globally:

```powershell
Install-Module -Name 'Carbon.IIS'
Import-Module -Name 'Carbon.IIS'
```

To install privately:

```powershell
Save-Module -Name 'Carbon.IIS' -Path '.'
Import-Module -Name '.\Carbon.IIS'
```

# Commands

* Add-CIisDefaultDocument
* Disable-CIisSecurityAuthentication
* Enable-CIisDirectoryBrowsing
* Enable-CIisSecurityAuthentication
* Enable-CIisHttps
* Get-CIisApplication
* Get-CIisAppPool
* Get-CIisConfigurationSection
* Get-CIisHttpHeader
* Get-CIisHttpRedirect
* Get-CIisMimeMap
* Get-CIisSecurityAuthentication
* Get-CIisVersion
* Get-CIisWebsite
* Install-CIisApplication
* Install-CIisAppPool
* Install-CIisVirtualDirectory
* Install-CIisWebsite
* Join-CIisPath
* Lock-CIisConfigurationSection
* Remove-CIisMimeMap
* Set-CIisHttpHeader
* Set-CIisHttpRedirect
* Set-CIisMimeMap
* Set-CIisWebsiteHttpsCertificate
* Set-CIisWindowsAuthentication
* Test-CIisAppPool
* Test-CIisConfigurationSection
* Test-CIisSecurityAuthentication
* Test-CIisWebsite
* Uninstall-CIisAppPool
* Uninstall-CIisWebsite
* Unlock-CIisConfigurationSection