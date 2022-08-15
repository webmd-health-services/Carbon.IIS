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
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:appPoolName = 'Carbon-Set-CIisWebsiteID'
    $script:siteName = 'Carbon-Set-CIisWebsiteID'
}

Describe 'Set-CIisWebsiteID' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
        Install-CIisAppPool -Name $script:appPoolName
        Install-CIisWebsite -Name $script:siteName `
                            -Binding 'http/*:61664:carbon-test-set-Ciiswebsiteid.com' `
                            -Path $script:TestDir `
                            -AppPoolName $script:appPoolName
        Write-Debug "# Set-CIisWebsiteID.BeforeEach"
        Get-CIisWebsite | Format-Table -Auto | Out-String | Write-Debug
    }

    AfterEach {
        Write-Debug "# Set-CIisWebsiteID.AfterEach"
        Get-CIisWebsite | Format-Table -Auto | Out-String | Write-Debug
        Uninstall-CIisWebsite $script:siteName
    }

    It 'should change ID' {
        $currentSite = Get-CIisWebsite -Name $script:siteName
        $currentSite | Should -Not -BeNullOrEmpty

        $newID = [int32](Get-Random -Maximum ([int32]::MaxValue) -Minimum 1)
        Set-CIisWebsiteID -SiteName $script:siteName -ID $newID -ErrorAction SilentlyContinue

        $updatedSite = Get-CIisWebsite -Name $script:siteName
        $updatedSite.ID | Should -Be $newID
    }

    It 'should detect duplicate IDs' {
        $alreadyTakenSiteName = 'AlreadyGotIt'
        $alreadyTakenSiteID = 4571
        $alreadyTakenSite = Install-CIisWebsite -Name $alreadyTakenSiteName `
                                                -PhysicalPath $PSScriptRoot `
                                                -Binding 'http/*:9983:' `
                                                -SiteID $alreadyTakenSiteID `
                                                -PassThru

        Get-CIisWebsite -Name $alreadyTakenSiteName |
            Select-Object -ExpandProperty 'ID' |
            Should -Be $alreadyTakenSiteID

        try
        {
            $currentSite = Get-CIisWebsite -Name $script:siteName
            $script:siteName | Should -Not -BeNullOrEmpty

            $alreadyTakenSite.ID | Should -Not -Be $currentSite.ID

            Get-CIisWebsite | Format-Table -Auto | Out-String | Write-Debug
            $Global:Error.Clear()
            Set-CIisWebsiteID -SiteName $script:siteName -ID $alreadyTakenSiteID -ErrorAction SilentlyContinue
            $Global:Error.Count | Should -Be 1
            $Global:Error | Should -BeLike '*is using ID*'
        }
        finally
        {
            Uninstall-CIisWebsite -Name $alreadyTakenSiteName
        }
    }

    It 'should handle non existent website' {
        $Global:Error.Clear()
        Get-CIisWebsite | Format-Table -Auto | Out-String | Write-Debug
        Set-CIisWebsiteID -SiteName 'HopefullyIDoNotExist' -ID 453879 -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 1
        $Global:Error[0].Exception.Message | Should -BeLike '*Website * not found*'
    }

    It 'should support WhatIf' {
        $currentSite = Get-CIisWebsite -Name $script:siteName
        $newID = [int32](Get-Random -Maximum ([int32]::MaxValue) -Minimum 1)
        Set-CIisWebsiteID -SiteName $script:siteName -ID $newID -WhatIf -ErrorAction SilentlyContinue
        $updatedsite = Get-CIisWebsite -Name $script:siteName
        $updatedsite.ID | Should -Be $currentSite.ID
    }

    It 'should set same ID on same website' {
        $Global:Error.Clear()
        $currentSite = Get-CIisWebsite -Name $script:siteName
        Set-CIisWebsiteID -SiteName $script:siteName -ID $currentSite.ID -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 0
        $updatedSite = Get-CIisWebsite -Name $script:siteName
        $updatedSite.ID | Should -Be $currentSite.ID
    }

}
