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

Describe 'Test-CIisConfigurationSection' {
    BeforeAll {
        & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)
    }

    It 'should find existing section' {
        (Test-CIisConfigurationSection -SectionPath 'system.webServer/cgi') | Should -BeTrue
    }

    It 'should not find missing section' {
        $Global:Error.Clear()
        (Test-CIisConfigurationSection -SectionPath 'system.webServer/u2') | Should -BeFalse
        $Global:Error | Should -HaveCount 2
    }


}
