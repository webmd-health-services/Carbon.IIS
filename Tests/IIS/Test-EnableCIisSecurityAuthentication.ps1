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
# limitations under the License.

$siteName = 'Anonymous Authentication'
$sitePort = 4387
$webConfigPath = Join-Path $TestDir web.config

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Uninstall-CIisWebsite $siteName
    Install-CIisWebsite -Name $siteName -Path $TestDir -Bindings "http://*:$sitePort"
    if( Test-Path $webConfigPath -PathType Leaf )
    {
        Remove-Item $webConfigPath
    }
}

function Stop-Test
{
    Uninstall-CIisWebsite $siteName
}

function Test-ShouldEnableAnonymousAuthentication
{
    Enable-CIisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-True (Test-CIisSecurityAuthentication -SiteName $siteName -Anonymous)
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableBasicAuthentication
{
    Enable-CIisSecurityAuthentication -SiteName $siteName -Basic
    Assert-True (Test-CIisSecurityAuthentication -SiteName $siteName -Basic)
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableWindowsAuthentication
{
    Enable-CIisSecurityAuthentication -SiteName $siteName -Windows
    Assert-True (Test-CIisSecurityAuthentication -SiteName $siteName -Windows)
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableAnonymousAuthenticationOnSubFolders
{
    Enable-CIisSecurityAuthentication -SiteName $siteName -Path SubFolder -Anonymous
    Assert-True (Test-CIisSecurityAuthentication -SiteName $siteName -Path SubFolder -Anonymous)
}

function Test-ShouldSupportWhatIf
{
    Disable-CIisSecurityAuthentication -SiteName $siteName -Anonymous
    Assert-False (Test-CIisSecurityAuthentication -SiteName $siteName -Anonymous)
    Enable-CIisSecurityAuthentication -SiteName $siteName -Anonymous -WhatIf
    Assert-False (Test-CIisSecurityAuthentication -SiteName $siteName -Anonymous)
}

