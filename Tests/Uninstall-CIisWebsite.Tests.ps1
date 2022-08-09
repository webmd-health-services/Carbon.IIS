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

    $script:siteName = 'TestSite'

    function ThenError
    {
        param(
            [Parameter(Mandatory)]
            [switch] $IsEmpty
        )

        $Global:Error | Should -BeNullOrEmpty
    }
    function ThenSiteDoesNotExist
    {
        param(
            [String] $Name = $script:siteName
        )

        Test-CIisWebsite -Name $Name | Should -BeFalse
    }

    function WhenRemovingSite
    {
        Uninstall-CIisWebsite $script:siteName
    }
}

Describe 'Uninstall-CIisWebsite' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:siteName -Path $script:testDir
        $Global:Error.Clear()
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should remove non existent site' {
        WhenRemovingSite
        ThenSiteDoesNotExist
        ThenError -IsEmpty
    }

    It 'should remove site' {
        WhenRemovingSite
        ThenSiteDoesNotExist
        ThenError -IsEmpty
    }
}
