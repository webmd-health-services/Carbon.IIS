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

    $script:appPoolName = 'CarbonTestUninstallAppPool'
}


Describe 'Uninstall-CIisAppPool' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        Install-CIisAppPool -Name $script:appPoolName
        Test-CIisAppPool -Name $script:appPoolName | Should -BeTrue
        $Global:Error.Clear()
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should remove app pool' {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Test-CIisAppPool -Name $script:appPoolName | Should -BeFalse
    }

    It 'should remvoe missing app pool' {
        $missingAppPool = 'IDoNotExist'
        Test-CIisAppPool -Name $missingAppPool | Should -BeFalse
        Uninstall-CIisAppPool -Name $missingAppPool
        Test-CIisAppPool -Name $missingAppPool | Should -BeFalse
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should support what if' {
        Uninstall-CIisAppPool -Name $script:appPoolName -WhatIf
        Test-CIisAppPool -Name $script:appPoolName | Should -BeTrue
    }

}
