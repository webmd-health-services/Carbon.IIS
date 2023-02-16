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
}

Describe 'Test-CIisAppPool' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should not find non existent app pool' {
        $exists = Test-CIisAppPool -Name 'ANameIMadeUpThatShouldNotExist'
        $exists | Should -BeFalse
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should find app pools' {
        $apppools = Get-CIisAppPool
        $apppools.Length | Should -BeGreaterThan 0
        foreach( $apppool in $apppools )
        {
            $exists = Test-CIisAppPool -Name $appPool.Name
            $exists | Should -BeTrue
        }
    }
}
