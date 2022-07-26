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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$InformationPreference = 'Continue'

# Functions should use $moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a 
# module in development has its functions in the Functions directory.
$moduleRoot = $PSScriptRoot

Import-Module -Name (Join-Path -Path $moduleRoot -ChildPath 'PSModules\Carbon.Core' -Resolve) `
              -Function @('Add-CTypeData')

if( [Environment]::SystemDirectory )
{
    $microsoftWebAdministrationPath =
        Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\Microsoft.Web.Administration.dll'
    if( $PSVersionTable['PSVersion'].Major -eq 6 )
    {
        $microsoftWebAdministrationPath = Join-Path -Path $moduleRoot -ChildPath 'bin\Microsoft.Web.Administration.dll'
    }
    
    if( (Test-Path -Path $microsoftWebAdministrationPath) )
    {
        Add-Type -Path $microsoftWebAdministrationPath
    }
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
$functionsPath = Join-Path -Path $moduleRoot -ChildPath 'Functions\*.ps1'
if( (Test-Path -Path $functionsPath) )
{
    foreach( $functionPath in (Get-Item $functionsPath) )
    {
        . $functionPath.FullName
    }
}
