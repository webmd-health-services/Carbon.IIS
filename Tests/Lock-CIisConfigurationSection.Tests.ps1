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

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:cgiWasLocked = $false
    $script:windowsAuthWasLocked = $false
    $script:windowsAuthConfigPath = 'system.webServer/security/authentication/windowsAuthentication'
    $script:cgiConfigPath = 'system.webServer/cgi'
}

Describe 'Lock-CIisConfigurationSection' {
    BeforeEach {
        $script:windowsAuthWasLocked = Test-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath -Locked
        Unlock-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath
        Test-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath -Locked | Should -BeFalse

        $script:cgiWasLocked = Test-CIisConfigurationSection -SectionPath $script:cgiConfigPath -Locked
        Unlock-CIisConfigurationSection -SectionPath $script:cgiConfigPath
        Test-CIisConfigurationSection -SectionPath $script:cgiConfigPath -Locked | Should -BeFalse
    }

    AfterEach {
        # Put things back the way we found them.
        if( $script:windowsAuthWasLocked )
        {
            Lock-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath
        }
        else
        {
            Unlock-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath
        }

        if( $script:cgiWasLocked )
        {
            Lock-CIisConfigurationSection -SectionPath $script:cgiConfigPath
        }
        else
        {
            Unlock-CIisConfigurationSection -SectionPath $script:cgiConfigPath
        }
    }

    It 'should lock one configuration section' {
        Lock-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath
        Test-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath -Locked | Should -BeTrue
    }

    It 'should unlock multiple configuration section' {
        Lock-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath,$script:cgiConfigPath
        Test-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath -Locked | Should -BeTrue
        (Test-CIisConfigurationSection -SectionPath $script:cgiConfigPath -Locked) | Should -BeTrue
    }

    It 'should support what if' {
        Test-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath -Locked | Should -BeFalse
        Lock-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath -WhatIf
        Test-CIisConfigurationSection -SectionPath $script:windowsAuthConfigPath -Locked | Should -BeFalse
    }

}
