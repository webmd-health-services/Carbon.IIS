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

    $script:appPoolName = 'Carbon-Get-CIisWebsite'
    $script:siteName = 'Carbon-Get-CIisWebsite'

    function Assert-ServerManagerMember
    {
        param(
            $Website
        )
        ($Website.ServerManager) | Should -Not -BeNullOrEmpty
        ($Website | Get-Member | Where-Object { $_.Name -eq 'CommitChanges' -and $_.MemberType -eq 'ScriptMethod' }) | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-CIisWebsite' {
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name $script:appPoolName
        $bindings = @( 'http/*:8401:', 'https/*:8401:', 'http/1.2.3.4:80:', "http/5.6.7.8:80:$script:siteName" )
        Install-CIisWebsite -Name $script:siteName -Bindings $bindings -Path $TestDrive -AppPoolName $script:appPoolName
    }

    AfterAll {
        Uninstall-CIisWebsite -Name $script:siteName
        Uninstall-CIisAppPool -Name $script:appPoolName
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should return null for non existent website' {
        $website = Get-CIisWebsite -SiteName 'ISureHopeIDoNotExist' -ErrorAction SilentlyContinue
        $website | Should -BeNullOrEmpty
        $Global:Error | Should -Match '"ISureHopeIDoNotExist" does not exist'
    }

    It 'should ignore when a website does not exist' {
        Get-CIisWebsite -SiteName 'fksjdfksdfklsdjfkl' -ErrorAction Ignore | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should get website details' {
        $website = Get-CIisWebsite -SiteName $script:siteName
        $website | Should -Not -BeNullOrEmpty
        $website.Name | Should -Be $script:siteName
        ($website.ID -gt 0) | Should -BeTrue
        $website.Bindings.Count | Should -Be 4
        $website.Bindings[0].Protocol | Should -Be 'http'
        $website.Bindings[0].Endpoint.Address | Should -Be '0.0.0.0'
        $website.Bindings[0].Endpoint.Port | Should -Be 8401
        $website.Bindings[0].Host | Should -BeNullOrEmpty

        $website.Bindings[1].Protocol | Should -Be 'https'
        $website.Bindings[1].Endpoint.Address | Should -Be '0.0.0.0'
        $website.Bindings[1].Endpoint.Port | Should -Be 8401
        $website.Bindings[1].Host | Should -BeNullOrEmpty

        $website.Bindings[2].Protocol | Should -Be 'http'
        $website.Bindings[2].Endpoint.Address | Should -Be '1.2.3.4'
        $website.Bindings[2].Endpoint.Port | Should -Be 80
        $website.Bindings[2].Host | Should -BeNullOrEmpty

        $website.Bindings[3].Protocol | Should -Be 'http'
        $website.Bindings[3].Endpoint.Address | Should -Be '5.6.7.8'
        $website.Bindings[3].Endpoint.Port | Should -Be 80
        $website.Bindings[3].Host | Should -Be $script:siteName

        $physicalPath = $website.Applications |
                            Where-Object { $_.Path -eq '/' } |
                            Select-Object -ExpandProperty VirtualDirectories |
                            Where-Object { $_.Path -eq '/' } |
                            Select-Object -ExpandProperty PhysicalPath
        $website.PhysicalPath | Should -Be $physicalPath

        Assert-ServerManagerMember -Website $website
    }

    It 'should get all websites' {
        $foundAtLeastOne = $false
        $foundTestWebsite = $false
        Get-CIisWebsite | ForEach-Object {
            $foundAtLeastOne = $true

            Assert-ServerManagerMember -Website $_

            if( $_.Name -eq $script:siteName )
            {
                $foundTestWebsite = $true
            }
        }

        $foundAtLeastOne | Should -BeTrue
        $foundTestWebsite | Should -BeTrue
    }
}
