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

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:siteName = 'SslFlags'
    $script:sitePort = 4389

    function Assert-SslFlags($ExpectedValue, $VirtualPath)
    {
        $Path = Join-CIisPath $script:SiteName $VirtualPath
        $authSettings = [xml] (& (Join-Path -Path $env:SystemRoot -ChildPath 'system32\inetsrv\appcmd.exe' -Resolve) list config $Path '-section:system.webServer/security/access')
        $sslFlags = $authSettings['system.webServer'].security.access.sslFlags
        $section =
            Get-CIisConfigurationSection -LocationPath (Join-CIisPath -Path $script:SiteName, $VirtualPath) `
                                         -SectionPath 'system.webServer/security/access'
        $sslIntFlags = $section['sslFlags']
        Write-Verbose ('{0} ({1})' -f $sslIntFlags,$sslFlags)
        $sslFlags | Should -Be $ExpectedValue
    }
}

Describe 'Enable-CIisSsl' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
        Uninstall-CIisWebsite $script:siteName
        Install-CIisWebsite -Name $script:siteName -Path $script:testDir -Bindings "http://*:$script:sitePort"
        $webConfigPath = Join-Path $script:testDir web.config
        if( Test-Path $webConfigPath -PathType Leaf )
        {
            Remove-Item $webConfigPath
        }
    }

    AfterEach {
        Uninstall-CIisWebsite $script:siteName
    }

    It 'should reset ssl flags' {
        Enable-CIisSsl -LocationPath $script:siteName
        Assert-SslFlags -ExpectedValue 'None'
    }

    It 'should require ssl' {
        Enable-CIisSsl -SiteName $script:siteName -RequireSSL
        Assert-SSLFlags -ExpectedValue 'Ssl'
    }

    It 'should accept client certificates' {
        Enable-CIisSsl -LocationPath $script:siteName -AcceptClientCertificates
        Assert-SSLFlags -ExpectedValue 'SslNegotiateCert'
    }

    It 'should require client certificates' {
        Enable-CIisSsl -LocationPath $script:siteName -RequireSsl -RequireClientCertificates
        Assert-SSLFlags -ExpectedValue 'Ssl, SslNegotiateCert, SslRequireCert'
    }

    It 'should allow128 bit ssl' {
        Enable-CIisSsl -LocationPath $script:siteName -Require128BitSsl
        Assert-SSLFlags -ExpectedValue 'Ssl128'
    }

    It 'should set all flags' {
        Enable-CIisSsl -LocationPath $script:siteName -RequireSsl -AcceptClientCertificates -Require128BitSsl
        Assert-SslFlags -ExpectedValue 'Ssl, SslNegotiatecert, Ssl128'
    }

    It 'should support what if' {
        Enable-CIisSsl -LocationPath $script:siteName -RequireSsl
        Assert-SslFlags -ExpectedValue 'Ssl'
        Enable-CIisSsl -LocationPath $script:siteName -AcceptClientCertificates -WhatIf
        Assert-SslFlags -ExpectedValue 'Ssl'
    }

    It 'should set flags on sub folder' {
        Enable-CIisSsl -LocationPath (Join-CIisPath $script:siteName, 'SubFolder') -RequireSsl
        Assert-SslFlags -ExpectedValue 'Ssl' -VirtualPath "SubFolder"
        Assert-SslFlags -ExpectedValue 'None'
    }

}
