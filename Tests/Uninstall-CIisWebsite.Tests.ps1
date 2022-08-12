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

    function GivenWebsite
    {
        [CmdletBinding()]
        param(
            [String] $Named
        )

        Install-CIisWebsite -Name $Named -Path $script:testDir -Binding "http/*:80:$($Named).localhost"

    }

    function ThenSite
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $Named,

            [switch] $Not,

            [Parameter(Mandatory, ParameterSetName='Exists')]
            [switch] $Exists
        )

        Test-CIisWebsite -Name $Named | Should -Not:$Not -BeTrue
    }

    function WhenRemovingSite
    {
        [CmdletBinding()]
        param(
            [hashtable] $WithArgs = @{}
        )

        Uninstall-CIisWebsite @WithArgs
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
        $Global:Error.Clear()
    }

    AfterEach {
        Get-CIisWebsite | Where-Object 'Name' -Like 'Uninstall*' | Uninstall-CIisWebsite
    }

    It 'should remove non existent site' {
        WhenRemovingSite -WithArgs @{ Name = 'UninstallOne' }
        ThenSite 'UninstallOne' -Not -Exists
        ThenError -Empty
    }

    It 'should remove site' {
        GivenWebsite 'UninstallTwo'
        WhenRemovingSite -WithArgs @{ Name = 'UninstallTwo' }
        ThenSite 'UninstallOne' -Not -Exists
        ThenError -Empty
    }

    It 'should remove multiple sites' {
        GivenWebsite 'UninstallThree'
        GivenWebsite 'UninstallFour'
        WhenRemovingSite -WithArgs @{ Name = @('UninstallThree', 'UninstallFour') }
        ThenSite 'UninstallThree' -Not -Exists
        ThenSite 'UninstallFour' -Not -Exists
        ThenError -Empty
    }

    It 'should accept pipeline input of site objects' {
        GivenWebsite 'UninstallFive'
        GivenWebsite 'UninstallSix'
        [Object[]] $sites = Get-CIisWebsite | Where-Object 'Name' -Like 'Uninstall*'
        $sites.Count | Should -BeGreaterThan 1
        $sites | Uninstall-CIisWebsite
        ThenSite 'UninstallFive' -Not -Exists
        ThenSite 'UninstallSix' -Not -Exists
        ThenError -Empty
    }

    It 'should accept pipeline input of names' {
        GivenWebsite 'UninstallSeven'
        GivenWebsite 'UninstallEight'
        [Object[]] $sites = Get-CIisWebsite | Where-Object 'Name' -Like 'Uninstall*'
        $sites.Count | Should -BeGreaterThan 1
        $sites.Name | Uninstall-CIisWebsite
        ThenSite 'UninstallSeven' -Not -Exists
        ThenSite 'UninstallEight' -Not -Exists
        ThenError -Empty
    }

    It 'should support WhatIf' {
        GivenWebsite 'UninstallNine'
        WhenRemovingSite -WithArgs @{ Name = 'UninstallNine' ; WhatIf = $true }
        ThenSite 'UninstallNine' -Exists
        ThenError -Empty
    }
}
