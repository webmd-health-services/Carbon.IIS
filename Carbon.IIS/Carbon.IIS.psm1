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

using module '.\Carbon.IIS.Enums.psm1'
using namespace System.Management.Automation
using namespace Microsoft.Web.Administration

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$InformationPreference = 'Continue'

# Functions should use $script:moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleRoot = $PSScriptRoot
$script:warningMessages = @{}
$script:applicationHostPath =
    Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config'
# These are all the files that could cause the current server manager object to become stale.
$script:iisConfigs = & {
    Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\*.config'
    Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'Microsoft.NET\Framework*\v*\config\*.config'
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'PSModules\Carbon.Core' -Resolve) `
              -Function @('Add-CTypeData', 'Resolve-CFullPath')

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'PSModules\Carbon.Windows.HttpServer' -Resolve) `
              -Function @('Set-CHttpsCertificateBinding')

function Test-MSWebAdministrationLoaded
{
    $serverMgrType =
        [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.Location -and ($_.Location | Split-Path -Leaf) -eq 'Microsoft.Web.Administration.dll' }
    return $null -ne $serverMgrType
}

$numErrorsAtStart = $Global:Error.Count
if( -not (Test-MSWebAdministrationLoaded) )
{
    $pathsToTry = & {
            # This is our preferred assembly. Always try it first.
            if( [Environment]::SystemDirectory )
            {
                $msWebAdminPath = Join-Path -Path ([Environment]::SystemDirectory) `
                                            -ChildPath 'inetsrv\Microsoft.Web.Administration.dll'
                Get-Item -Path $msWebAdminPath -ErrorAction SilentlyContinue
            }

            # If any IIS module is installed, it might have a copy. Find them but make sure they are sorted from
            # newest version to oldest version.
            Get-Module -Name 'IISAdministration', 'WebAdministration' -ListAvailable |
                Select-Object -ExpandProperty 'Path' |
                Split-Path -Parent |
                Get-ChildItem -Filter 'Microsoft.Web.Administration.dll' -Recurse -ErrorAction SilentlyContinue |
                Sort-Object { [Version]$_.VersionInfo.FileVersion } -Descending
        }

    foreach( $pathToTry in $pathsToTry )
    {
        try
        {
            Add-Type -Path $pathToTry.FullName
            Write-Debug "Loaded required assembly Microsoft.Web.Administration from ""$($pathToTry)""."
            break
        }
        catch
        {
            Write-Debug "Failed to load assembly ""$($pathToTry)"": $($_)."
        }
    }
}

if( -not (Test-MSWebAdministrationLoaded) )
{
    try
    {
        Add-Type -AssemblyName 'Microsoft.Web.Administration' `
                 -ErrorAction SilentlyContinue `
                 -ErrorVariable 'addTypeErrors'
        if( -not $addTypeErrors )
        {
            Write-Debug "Loaded required assembly Microsoft.Web.Administration from GAC."
        }
    }
    catch
    {
    }
}

if( -not (Test-MSWebAdministrationLoaded) )
{
    Write-Error -Message "Unable to find and load required assembly Microsoft.Web.Administration." -ErrorAction Stop
    return
}

$script:serverMgr = [Microsoft.Web.Administration.ServerManager]::New()
$script:serverMgrCreatedAt = [DateTime]::UtcNow
if( -not $script:serverMgr -or $null -eq $script:serverMgr.ApplicationPoolDefaults )
{
    Write-Error -Message "Carbon.IIS is not supported on this version of PowerShell." -ErrorAction Stop
    return
}

# We successfully loaded Microsoft.Web.Administration assembly, so remove the errors we encountered trying to do so.
for( $idx = $Global:Error.Count ; $idx -gt $numErrorsAtStart ; --$idx )
{
    $Global:Error.RemoveAt(0)
}

Add-CTypeData -TypeName 'Microsoft.Web.Administration.Site' `
              -MemberType ScriptProperty `
              -MemberName 'PhysicalPath' `
              -Value {
                    $this.Applications |
                        Where-Object 'Path' -EQ '/' |
                        Select-Object -ExpandProperty 'VirtualDirectories' |
                        Where-Object 'Path' -EQ '/' |
                        Select-Object -ExpandProperty 'PhysicalPath'
                }

Add-CTypeData -TypeName 'Microsoft.Web.Administration.Application' `
              -MemberType ScriptProperty `
              -MemberName 'PhysicalPath' `
              -Value {
                    $this.VirtualDirectories |
                        Where-Object 'Path' -EQ '/' |
                        Select-Object -ExpandProperty 'PhysicalPath'
                }

# Store each of your module's functions in its own file in the Functions
# directory. On the build server, your module's functions will be appended to
# this file, so only dot-source files that exist on the file system. This allows
# developers to work on a module without having to build it first. Grab all the
# functions that are in their own files.
$functionsPath = & {
    Join-Path -Path $script:moduleRoot -ChildPath 'Functions\*.ps1'
    Join-Path -Path $script:moduleRoot -ChildPath 'Carbon.IIS.ArgumentCompleters.ps1'
}
foreach ($importPath in $functionsPath)
{
    if( -not (Test-Path -Path $importPath) )
    {
        continue
    }

    foreach( $fileInfo in (Get-Item $importPath) )
    {
        . $fileInfo.FullName
    }
}
