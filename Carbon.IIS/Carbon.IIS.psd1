# Copyright WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'Carbon.IIS.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = '157f0f80-4787-4dc0-bdee-4881c627750b'

    # Author of this module
    Author = 'Aaron Jensen'

    # Company or vendor of this module
    CompanyName = ''

    # If you want to support .NET Core, add 'Core' to this list.
    CompatiblePSEditions = @( 'Desktop', 'Core' )

    # Copyright statement for this module
    Copyright = 'Aaron Jensen and WebMD Health Services'

    # Description of the functionality provided by this module
    Description = 'Carbon.IIS is a module for installing and managing IIS app pools, websites, applications, and configuring other parts of IIS.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @( )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @( )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module. Only list public function here.
    FunctionsToExport = @(
        'Add-CIisDefaultDocument',
        'ConvertTo-CIisVirtualPath',
        'Disable-CIisSecurityAuthentication',
        'Enable-CIisDirectoryBrowsing',
        'Enable-CIisSecurityAuthentication',
        'Enable-CIisSsl',
        'Get-CIisApplication',
        'Get-CIisAppPool',
        'Get-CIisConfigurationSection',
        'Get-CIisConfigurationLocationPath',
        'Get-CIisHttpHeader',
        'Get-CIisHttpRedirect',
        'Get-CIisMimeMap',
        'Get-CIisSecurityAuthentication',
        'Get-CIisVersion',
        'Get-CIisVirtualDirectory',
        'Get-CIisWebsite',
        'Install-CIisApplication',
        'Install-CIisAppPool',
        'Install-CIisVirtualDirectory',
        'Install-CIisWebsite',
        'Join-CIisVirtualPath',
        'Lock-CIisConfigurationSection',
        'Remove-CIisConfigurationAttribute',
        'Remove-CIisConfigurationLocation',
        'Remove-CIisMimeMap',
        'Restart-CIisAppPool',
        'Save-CIisConfiguration',
        'Set-CIisAnonymousAuthentication',
        'Set-CIisAppPool',
        'Set-CIisAppPoolCpu',
        'Set-CIisAppPoolPeriodicRestart',
        'Set-CIisAppPoolProcessModel',
        'Set-CIisAppPoolRecycling',
        'Set-CIisConfigurationAttribute',
        'Set-CIisHttpHeader',
        'Set-CIisHttpRedirect',
        'Set-CIisMimeMap',
        'Set-CIisWebsite',
        'Set-CIisWebsiteID',
        'Set-CIisWebsiteLimit',
        'Set-CIisWebsiteLogFile',
        'Set-CIisWebsiteSslCertificate',
        'Set-CIisWindowsAuthentication',
        'Start-CIisAppPool',
        'Stop-CIisAppPool',
        'Test-CIisAppPool',
        'Test-CIisConfigurationSection',
        'Test-CIisSecurityAuthentication',
        'Test-CIisWebsite',
        'Uninstall-CIisAppPool',
        'Uninstall-CIisWebsite',
        'Unlock-CIisConfigurationSection'
    )

    # Cmdlets to export from this module. By default, you get a script module, so there are no cmdlets.
    # CmdletsToExport = @()

    # Variables to export from this module. Don't export variables except in RARE instances.
    VariablesToExport = @()

    # Aliases to export from this module. Don't create/export aliases. It can pollute your user's sessions.
    # AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @( 'Desktop', 'Core', 'iis', 'website', 'app', 'pool', 'http', 'https', 'ssl', 'tls', 'web.config',
                      'applicationHost.config', 'application', 'default', 'document', 'server', 'manager', 'security',
                      'authentication', 'configuration', 'section', 'mime', 'map', 'directory', 'browsing', 'redirect',
                      'virtual', 'header', 'id', 'certificate', 'windows', 'anonymous', 'basic',  'lock', 'unlock',
                      'WebAdministration', 'Microsoft.Web.Administration', 'Carbon' )

            # A URL to the license for this module.
            LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'

            # A URL to the main website for this project.
            ProjectUri = 'http://get-carbon.org/'

            # A URL to an icon representing this module.
            # IconUri = ''

            Prerelease = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/webmd-health-services/Carbon.IIS/blob/master/CHANGELOG.md'
        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
