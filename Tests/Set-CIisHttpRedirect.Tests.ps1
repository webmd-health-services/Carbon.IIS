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

    $script:webConfigPath = ''
    $script:appPoolName = $PSCommandPath | Split-Path -Leaf
    $script:testWebRoot = ''
    $script:testNum = 0
}

Describe 'Set-CIisHttpRedirect' {
    BeforeAll {
        Install-CIisAppPool -Name $script:appPoolName
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testWebRoot = New-TestDirectory
        $script:port = Get-Port
        $script:siteName = "$($script:appPoolName)$($script:testNum)"
        $script:testNum++
        Install-CIisWebsite -Name $script:siteName `
                            -Path $script:testWebRoot `
                            -Bindings "http://*:$($script:port)" `
                            -AppPoolName $script:appPoolName
        $script:webConfigPath = Join-Path -Path $script:testWebRoot -ChildPath 'web.config'
        if( Test-Path $script:webConfigPath )
        {
            Remove-Item $script:webConfigPath
        }
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should redirect site' {
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com' -Enabled $true
        ThenUrlContent "http://localhost:$($script:port)" -Match 'Example Domain'
        $script:webConfigPath | Should -Not -Exist # make sure committed to applicationHost.config
        $settings = Get-CIisHttpRedirect -SiteName $script:siteName
        $settings.GetAttributeValue('Enabled') | Should -BeTrue
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
        $settings.GetAttributeValue('exactDestination') | Should -BeFalse
        $settings.GetAttributeValue('childOnly') | Should -BeFalse
        $settings.GetAttributeValue('httpResponseStatus') | Should -Be 302
    }

    It 'should set redirect customizations' {
        Set-CIisHttpRedirect -SiteName $script:siteName `
                             -Enabled $true `
                             -Destination 'http://www.example.com' `
                             -HttpResponseStatus Permanent `
                             -ExactDestination $true `
                             -ChildOnly $true
        ThenUrlContent "http://localhost:$($script:port)" -Match 'Example Domain'
        $settings = Get-CIisHttpRedirect -SiteName $script:siteName
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
        $settings.GetAttributeValue('httpResponseStatus') | Should -Be 301
        $settings.GetAttributeValue('exactDestination') | Should -BeTrue
        $settings.GetAttributeValue('childOnly') | Should -BeTrue
    }

    It 'should set to default values' {
        Set-CIisHttpRedirect -SiteName $script:siteName `
                             -Enabled $true `
                             -Destination 'http://www.example.com' `
                             -HttpResponseStatus 301 `
                             -ExactDestination $true `
                             -ChildOnly $true
        ThenUrlContent "http://localhost:$($script:port)" -Match 'Example Domain'
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com' -Reset

        $settings = Get-CIisHttpRedirect -SiteName $script:siteName
        $settings.GetAttributeValue('enabled') | Should -BeFalse
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
        $settings.GetAttributeValue('httpResponseStatus') | Should -Be 302
        $settings.GetAttributeValue('exactDestination') | Should -BeFalse
        $settings.GetAttributeValue('childOnly') | Should -BeFalse
    }

    It 'should set redirect on path' {
        $PSCommandPath | Set-Content -Path (Join-Path -Path $script:testWebRoot -ChildPath 'index.html') -NoNewLine

        New-Item -Path (Join-Path -Path $script:testWebRoot -ChildPath 'SubFolder') -ItemType 'Directory'

        $locationPath = $script:siteName, 'SubFolder' | Join-CIisPath

        Set-CIisHttpRedirect -LocationPath $locationPath -Enabled $true -Destination 'http://www.example.com'
        ThenUrlContent "http://localhost:$($script:port)/SubFolder" -Match 'Example Domain'
        ThenUrlContent "http://localhost:$($script:port)/" -Is $PSCommandPath

        $settings = Get-CIisHttpRedirect -LocationPath $locationPath
        $settings.GetAttributeValue('enabled') | Should -BeTrue
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
    }
}
