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

    $script:appPoolName = 'CarbonGetIisAppPool'
}

Describe 'Get-CIisAppPool' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        Install-CIisAppPool -Name $script:appPoolName
        $Global:Error.Clear()
    }

    AfterEach {
        if( (Test-CIisAppPool -Name $script:appPoolName) )
        {
            Uninstall-CIisAppPool -Name $script:appPoolName
        }
    }

    It 'should get all application pools' {
        Install-CIisAppPool -Name 'ShouldGetAllApplicationPools'
        Install-CIisAppPool -Name 'ShouldGetAllApplicationPools2'
        try
        {
            $appPools = Get-CIisAppPool
            $appPools | Should -Not -BeNullOrEmpty
            $appPools | Should -BeOfType ([Microsoft.Web.Administration.ApplicationPool])
            ($appPools | Where-Object { $_.Name -eq 'ShouldGetAllApplicationPools' }) | Should -Not -BeNullOrEmpty
            ($appPools | Where-Object { $_.Name -eq 'ShouldGetAllApplicationPools2' }) | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Uninstall-CIisAppPool -Name 'ShouldGetAllApplicationPools'
            Uninstall-CIisAppPool -Name 'ShouldGetAllApplicationPools2'
        }
    }

    It 'should add server manager members' {
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool | Should -Not -BeNullOrEmpty
        $appPool.ServerManager | Should -Not -BeNullOrEmpty
        $newAppPoolName = 'New{0}' -f $script:appPoolName
        Uninstall-CIisAppPool -Name $newAppPoolName
        $appPool.name = $newAppPoolName
        $appPool.CommitChanges()

        try
        {
            $appPool = Get-CIisAppPool -Name $newAppPoolName
            $appPool | Should -Not -BeNullOrEmpty
            $appPool.name | Should -Be $newAppPoolName
        }
        finally
        {
            Uninstall-CIisAppPool -Name $newAppPoolName
        }
    }

    It 'should write an error if app pool does not exist' {
        $appPool = Get-CIisAppPool -Name '79' -ErrorAction SilentlyContinue
        $appPool | Should -BeNullOrEmpty
        ThenError -Is "IIS application pool ""79"" does not exist."
    }

    It 'should ignore errors when an app pool does not exist' {
        $appPool = Get-CIisAppPool -Name '79' -ErrorAction Ignore
        $appPool | Should -BeNullOrEmpty
        ThenError -Empty
    }

}
