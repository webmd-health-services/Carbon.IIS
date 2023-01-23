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

    function ThenHttpFlags($ExpectedValue, $VirtualPath)
    {
        $Path = Join-CIisPath $script:SiteName $VirtualPath
        $authSettings = [xml] (& (Join-Path -Path $env:SystemRoot -ChildPath 'system32\inetsrv\appcmd.exe' -Resolve) list config $Path '-section:system.webServer/security/access')
        $httpsFlags = $authSettings['system.webServer'].security.access.sslFlags
        $section =
            Get-CIisConfigurationSection -LocationPath (Join-CIisPath -Path $script:SiteName, $VirtualPath) `
                                         -SectionPath 'system.webServer/security/access'
        $httpsIntFlags = $section['sslFlags']
        Write-Verbose ('{0} ({1})' -f $httpsIntFlags,$httpsFlags)
        $httpsFlags | Should -Be $ExpectedValue
    }
}

Describe 'Enable-CIisHttps' {
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

    It 'should reset HTTPS flags' {
        Enable-CIisHttps -LocationPath $script:siteName
        ThenHttpFlags -ExpectedValue 'None'
    }

    It 'should require HTTPS' {
        Enable-CIisHttps -SiteName $script:siteName -RequireHttps
        ThenHttpFlags -ExpectedValue 'Ssl'
    }

    It 'should accept client certificates' {
        Enable-CIisHttps -LocationPath $script:siteName -AcceptClientCertificates
        ThenHttpFlags -ExpectedValue 'SslNegotiateCert'
    }

    It 'should require client certificates' {
        Enable-CIisHttps -LocationPath $script:siteName -RequireHttps -RequireClientCertificates
        ThenHttpFlags -ExpectedValue 'Ssl, SslNegotiateCert, SslRequireCert'
    }

    It 'should allow 128 bit HTTPS' {
        Enable-CIisHttps -LocationPath $script:siteName -Require128BitHttps
        ThenHttpFlags -ExpectedValue 'Ssl128'
    }

    It 'should set all flags' {
        Enable-CIisHttps -LocationPath $script:siteName -RequireHttps -AcceptClientCertificates -Require128BitHttps
        ThenHttpFlags -ExpectedValue 'Ssl, SslNegotiatecert, Ssl128'
    }

    It 'should support what if' {
        Enable-CIisHttps -LocationPath $script:siteName -RequireHttps
        ThenHttpFlags -ExpectedValue 'Ssl'
        Enable-CIisHttps -LocationPath $script:siteName -AcceptClientCertificates -WhatIf
        ThenHttpFlags -ExpectedValue 'Ssl'
    }

    It 'should set flags on sub folder' {
        Enable-CIisHttps -LocationPath (Join-CIisPath $script:siteName, 'SubFolder') -RequireHttps
        ThenHttpFlags -ExpectedValue 'Ssl' -VirtualPath "SubFolder"
        ThenHttpFlags -ExpectedValue 'None'
    }

}
