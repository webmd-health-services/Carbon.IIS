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

& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

$appPoolName = 'Carbon-Set-CIisWebsiteID'
$siteName = 'Carbon-Set-CIisWebsiteID'

Describe 'Set-CIisWebsiteID' {
    BeforeEach {
        $testDir = Join-Path -Path $TestDrive.FullName -ChildPath ([IO.Path]::GetRandomFileName())
        New-Item -Path $testDir -ItemType 'Directory'
        Install-CIisAppPool -Name $appPoolName
        Install-CIisWebsite -Name $siteName -Binding 'http/*:61664:carbon-test-set-Ciiswebsiteid.com' -Path $TestDir -AppPoolName $appPoolName
    }
    
    AfterEach {
        Remove-CIisWebsite $siteName
    }
    
    It 'should change ID' {
        $currentSite = Get-CIisWebsite -SiteName $siteName
        $currentSite | Should -Not -BeNullOrEmpty
        # Make sure the website is already started.
        $currentSite.Start()
    
        $newID = [int32](Get-Random -Maximum ([int32]::MaxValue) -Minimum 1)
        Set-CIisWebsiteID -SiteName $siteName -ID $newID -ErrorAction SilentlyContinue
    
        $updatedSite = Get-CIisWebsite -SiteName $siteName
        $updatedSite.ID | Should -Be $newID
        $updatedSite.State | Should -Be 'Started'
    }
    
    It 'should detect duplicate IDs' {
        $alreadyTakenSiteName = 'AlreadyGotIt'
        $alreadyTakenSiteID = 4571
        $alreadyTakenSite = Install-CIisWebsite -Name $alreadyTakenSiteName `
                                               -PhysicalPath $PSScriptRoot `
                                               -Binding 'http/*:9983:' `
                                               -SiteID $alreadyTakenSiteID `
                                               -PassThru
        try
        {
            $currentSite = Get-CIisWebsite -SiteName $siteName
            $siteName | Should -Not -BeNullOrEmpty
    
            $alreadyTakenSite.ID | Should -Not -Be $currentSite.ID
    
            $Error.Clear()
            Set-CIisWebsiteID -SiteName $siteName -ID $alreadyTakenSiteID -ErrorAction SilentlyContinue
            $Error.Count | Should -Be 1
            $Error[0].Exception.Message | Should -BeLike '*ID * already in use*'
        }
        finally
        {
            Uninstall-CIisWebsite -Name $alreadyTakenSiteName
        }
    }
    
    It 'should handle non existent website' {
        $Error.Clear()
        Set-CIisWebsiteID -SiteName 'HopefullyIDoNotExist' -ID 453879 -ErrorAction SilentlyContinue
        $Error.Count | Should -Be 1
        $Error[0].Exception.Message | Should -BeLike '*Website * not found*'
    }
    
    It 'should support what if' {
        $currentSite = Get-CIisWebsite -SiteName $siteName
        $newID = [int32](Get-Random -Maximum ([int32]::MaxValue) -Minimum 1)
        Set-CIisWebsiteID -SiteName $siteName -ID $newID -WhatIf -ErrorAction SilentlyContinue
        $updatedsite = Get-CIisWebsite -SiteName $siteName
        $updatedsite.ID | Should -Be $currentSite.ID
    }
    
    It 'should set same ID on same website' {
        $Error.Clear()
        $currentSite = Get-CIisWebsite -SiteName $siteName
        $currentSite.Start()
        Set-CIisWebsiteID -SiteName $siteName -ID $currentSite.ID -ErrorAction SilentlyContinue
        $Error.Count | Should -Be 0
        $updatedSite = Get-CIisWebsite -SiteName $siteName
        $updatedSite.ID | Should -Be $currentSite.ID
        $updatedSite.State | Should -Be 'Started'
    }
    
}
