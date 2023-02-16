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
    Write-Debug 'BeforeAll'
    $script:siteName = 'Anonymous Authentication'
    $script:sitePort = 4387

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
}

Describe 'Disable-CIisSecurityAuthentication' {
    BeforeAll {
        Write-Debug 'BeforeAll'
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Write-Debug 'AfterAll'
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        Write-Debug 'BeforeEach'
        $script:webRoot = New-TestDirectory
        Uninstall-CIisWebsite $script:siteName
        Install-CIisWebsite -Name $script:siteName -Path $script:webRoot -Bindings "http://*:$script:sitePort"

        $webConfigPath = Join-Path -Path $script:webRoot -ChildPath 'web.config'
        if( Test-Path -Path $webConfigPath)
        {
            Remove-Item -Path $webConfigPath
        }
        Write-Debug 'It'
    }

    AfterEach {
        Write-Debug 'AfterEach'
        Uninstall-CIisWebsite $script:siteName
    }

    It 'should disable anonymous authentication on vdir' {
        $locationPath = $script:siteName, 'SubFolder' | Join-CIisPath
        Disable-CIisSecurityAuthentication -LocationPath $locationPath -Anonymous
        Test-CIisSecurityAuthentication -LocationPath $locationPath -Anonymous | Should -BeFalse
    }

    It 'should disable anonymous authentication' {
        Disable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeFalse
    }

    It 'should disable basic authentication' {
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Basic
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Basic) | Should -BeTrue
        Disable-CIisSecurityAuthentication -SiteName $script:siteName -Basic
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Basic) | Should -BeFalse
    }

    It 'should disable windows authentication' {
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Windows
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Windows) | Should -BeTrue
        Disable-CIisSecurityAuthentication -SiteName $script:siteName -Windows
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Windows) | Should -BeFalse
    }

    It 'should disable enabled anonymous authentication' {
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeTrue
        Disable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeFalse
    }

    It 'should support WhatIf' {
        Enable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeTrue
        Disable-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous -WhatIf
        (Test-CIisSecurityAuthentication -SiteName $script:siteName -Anonymous) | Should -BeTrue
    }
}
