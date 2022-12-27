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
    $script:siteName = 'Anonymous Authentication'
    $script:sitePort = 4387
    $script:webConfigPath = ''

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
}

Describe 'Enable-CIisSecurityAuthentication' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testWebRoot = New-TestDirectory
        Uninstall-CIisWebsite $script:siteName
        Install-CIisWebsite -Name $script:siteName -Path $script:testWebRoot -Bindings "http://*:$script:sitePort"
        $script:webConfigPath = Join-Path -Path $script:testWebRoot -ChildPath 'web.config'
        if( Test-Path -Path $script:webConfigPath  )
        {
            Remove-Item -Path $script:webConfigPath
        }
    }

    AfterEach {
        Uninstall-CIisWebsite $script:siteName
    }

    It 'should enable anonymous authentication' {
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeTrue
        $script:webConfigPath | Should -Not -Exist
    }

    It 'should enable basic authentication' {
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Basic
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Basic) | Should -BeTrue
        $script:webConfigPath | Should -Not -Exist
    }

    It 'should enable windows authentication' {
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Windows
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Windows) | Should -BeTrue
        $script:webConfigPath | Should -Not -Exist
    }

    It 'should enable anonymous authentication on sub folders' {
        $locationPath = $script:siteName,'SubFolder' | Join-CIisPath
        Enable-CIisSecurityAuthentication -LocationPath $locationPath  -Anonymous
        (Test-CIisSecurityAuthentication -LocationPath $locationPath -Anonymous) | Should -BeTrue
    }

    It 'should support what if' {
        Disable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeFalse
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous -WhatIf
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeFalse
    }

}
