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

$siteName = 'SslFlags'
$sitePort = 4389
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

function Test-ShouldResetSslFlags
{
    Enable-CIisSsl -SiteName $siteName
    Assert-SslFlags -ExpectedValue 'None'
}

function Test-ShouldRequireSsl
{
    Enable-CIisSsl -SiteName $siteName -RequireSSL
    Assert-SSLFlags -ExpectedValue 'Ssl'
}

function Test-ShouldAcceptClientCertificates
{
    Enable-CIisSsl -SiteName $siteName -AcceptClientCertificates
    Assert-SSLFlags -ExpectedValue 'SslNegotiateCert'
}

function Test-ShouldRequireClientCertificates
{
    Enable-CIisSsl -SiteName $siteName -RequireSsl -RequireClientCertificates
    Assert-SSLFlags -ExpectedValue 'Ssl, SslNegotiateCert, SslRequireCert'
}

function Test-ShouldAllow128BitSsl
{
    Enable-CIisSsl -SiteName $siteName -Require128BitSsl
    Assert-SSLFlags -ExpectedValue 'Ssl128'
}

function Test-ShouldSetAllFlags
{
    Enable-CIisSsl -SiteName $siteName -RequireSsl -AcceptClientCertificates -Require128BitSsl
    Assert-SslFlags -ExpectedValue 'Ssl, SslNegotiatecert, Ssl128'
}

function Test-ShouldSupportWhatIf
{
    Enable-CIisSsl -SiteName $siteName -RequireSsl
    Assert-SslFlags -ExpectedValue 'Ssl'
    Enable-CIisSsl -SiteName $siteName -AcceptClientCertificates -WhatIf
    Assert-SslFlags -ExpectedValue 'Ssl'
}

function Test-ShouldSetFlagsOnSubFolder
{
    Enable-CIisSsl -SiteName $siteName -Path SubFolder -RequireSsl
    Assert-SslFlags -ExpectedValue 'Ssl' -VirtualPath "SubFolder"
    Assert-SslFlags -ExpectedValue 'None'
}

function Assert-SslFlags($ExpectedValue, $VirtualPath)
{
    $Path = Join-CIisVirtualPath $SiteName $VirtualPath
    $authSettings = [xml] (& (Join-Path -Path $env:SystemRoot -ChildPath 'system32\inetsrv\appcmd.exe' -Resolve) list config $Path '-section:system.webServer/security/access')
    $sslFlags = $authSettings['system.webServer'].security.access.sslFlags
    $section = Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath 'system.webServer/security/access'
    $sslIntFlags = $section['sslFlags']
    Write-Verbose ('{0} ({1})' -f $sslIntFlags,$sslFlags)
    Assert-Equal $ExpectedValue $sslFlags
}

