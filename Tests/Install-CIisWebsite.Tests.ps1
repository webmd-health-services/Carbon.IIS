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
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:siteName = 'TestNewWebsite'
    $script:testDir = $null

    function Assert-WebsiteBinding
    {
        param(
            [string[]]
            $Binding
        )

        $website = Get-CIisWebsite -Name $script:siteName
        [string[]]$actualBindings = $website.Bindings | ForEach-Object { $_.ToString() }
        $actualBindings.Count | Should -Be $Binding.Count
        foreach( $item in $Binding )
        {
            ($actualBindings -contains $item) | Should -BeTrue
        }
    }

    function Assert-WebsiteRunning($port)
    {
        $browser = New-Object Net.WebClient
        $html = $browser.downloadString( "http://localhost:$($port)/" )
        $html | Should -BeLike '*NewWebsite Test Page*'
    }

    function Invoke-NewWebsite($Bindings = $null, $SiteID)
    {
        $optionalParams = @{ }
        if( $PSBoundParameters.ContainsKey( 'SiteID' ) )
        {
            $optionalParams['ID'] = $SiteID
        }

        if( $PSBoundParameters.ContainsKey( 'Bindings' ) )
        {
            $optionalParams['Bindings'] = $Bindings
        }

        'NewWebsite Test Page' | Set-Content -Path (Join-Path -Path $script:testDir -ChildPath 'index.html')
        $site = Install-CIisWebsite -Name $script:siteName -Path $script:testDir @optionalParams
        $site | Should -BeNullOrEmpty
        $Global:Error.Count | Should -Be 0
    }

    function Remove-TestSite
    {
        while( $true )
        {
            Uninstall-CIisWebsite -Name $script:siteName
            if( -not (Test-CIisWebsite -Name $script:siteName) )
            {
                break
            }

            Write-Warning -Message ('Waiting for website to get uninstalled.')
            Start-Sleep -Milliseconds 100
        }
    }

    function Wait-ForWebsiteToBeRunning
    {
        $tryNum = 0
        do
        {
            $tryNum += 1
            $website = Get-CIisWebsite -Name $script:siteName
            if( $website.State -eq 'Started' )
            {
                break
            }

            try
            {
                $website.Start()
            }
            catch
            {
                Write-Warning -Message ('Exception trying to start website "{0}": {1}' -f $script:siteName,$_)
                $Global:Error.RemoveAt(0)
            }
            Start-Sleep -Milliseconds 100
        }
	while( $tryNum -lt 100 )

        $website.State | Should -Be 'Started'
    }

}

Describe 'Install-CIisWebsite' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = New-TestDirectory
        Remove-TestSite
    }

    AfterEach {
        Remove-TestSite
    }

    It 'should create website' {
        Invoke-NewWebsite -SiteID 5478

        $details = Get-CIisWebsite -Name $script:siteName
        $details | Should -Not -BeNullOrEmpty
        $details | Should -BeLike $script:siteName
        $details.Bindings[0].Protocol | Should -Be 'http'
        $details.Bindings[0].BindingInformation | Should -Be '*:80:'

        $details.PhysicalPath | Should -Be $script:testDir

        $anonymousAuthInfo = Get-CIisSecurityAuthentication -Anonymous -SiteName $script:siteName
        $anonymousAuthInfo['userName'] | Should -Be 'IUSR'

        $website = Get-CIisWebsite -Name $script:siteName
        $website | Should -Not -BeNullOrEmpty
        $website.Id | Should -Be 5478
    }

    It 'should resolve relative path' {
        $newDirName = [IO.Path]::GetRandomFileName()
        $newDir = Join-Path -Path $script:testDir -ChildPath ('..\{0}' -f $newDirName)
        New-Item -Path $newDir -ItemType 'Directory'
        Install-CIisWebsite -Name $script:siteName -Path ('{0}\..\{1}' -f $script:testDir,$newDirName)
        $site = Get-CIisWebsite -Name $script:siteName
        $site | Should -Not -BeNullOrEmpty
        $site.PhysicalPath | Should -Be ([IO.Path]::GetFullPath($newDir))
    }

    It 'should create website with custom binding' {
        Invoke-NewWebsite -Bindings 'http/*:9876:'
        Wait-ForWebsiteToBeRunning
        Assert-WebsiteRunning 9876
    }

    It 'should create website with multiple bindings' {
        Invoke-NewWebsite -Bindings 'http/*:9876:','http/*:9877:'
        Wait-ForWebsiteToBeRunning
        Assert-WebsiteRunning 9876
        Assert-WebsiteRunning 9877
    }

    It 'should add site to custom app pool' {
        Install-CIisAppPool -Name $script:siteName

        try
        {
            Install-CIisWebsite -Name $script:siteName -Path $script:testDir -AppPoolName $script:siteName
            $appPool = Get-CIisWebsite -Name $script:siteName
            $appPool = $appPool.Applications[0].ApplicationPoolName
        }
        finally
        {
            Uninstall-CIisAppPool $script:siteName
        }

        $appPool | Should -Be $script:siteName
    }

    It 'should update existing site' {
        Invoke-NewWebsite -Bindings 'http/*:9876:'
        $Global:Error | Should -BeNullOrEmpty
        (Test-CIisWebsite -Name $script:siteName) | Should -BeTrue
        Install-CIisVirtualDirectory -SiteName $script:siteName `
                                     -VirtualPath '/ShouldStillHangAround' `
                                     -PhysicalPath $PSScriptRoot

        Invoke-NewWebsite
        $Global:Error | Should -BeNullOrEmpty
        (Test-CIisWebsite -Name $script:siteName) | Should -BeTrue

        $website = Get-CIisWebsite -Name $script:siteName
        ($website.Applications[0].VirtualDirectories | Where-Object { $_.Path -eq '/ShouldStillHangAround' } ) | Should -Not -BeNullOrEmpty
    }

    It 'should create site directory' {
        $websitePath = Join-Path $script:testDir ShouldCreateSiteDirectory
        if( Test-Path $websitePath -PathType Container )
        {
            $null = Remove-Item $websitePath -Force
        }

        try
        {
            Install-CIisWebsite -Name $script:siteName -Path $websitePath -Bindings 'http/*:9876:'
            Test-Path -Path $websitePath -PathType Container | Should -BeTrue
        }
        finally
        {
            if( Test-Path $websitePath -PathType Container )
            {
                $null = Remove-Item $websitePath -Force
            }
        }
    }

    It 'should validate bindings' {
        $Global:Error.Clear()
        Install-CIisWebsite -Name $script:siteName -Path $script:testDir -Bindings 'http/*' -ErrorAction SilentlyContinue
        $Global:Error | Should -Not -BeNullOrEmpty
        (Test-CIisWebsite -Name $script:siteName) | Should -BeFalse
        $Global:Error | Should -Not -BeNullOrEmpty
        $Global:Error[0] | Should -Match 'bindings are invalid'
    }

    It 'should allow url bindings' {
        Invoke-NewWebsite -Bindings 'http://*:9876'
        (Test-CIisWebsite -Name $script:siteName) | Should -BeTrue
        Wait-ForWebsiteToBeRunning
        Assert-WebsiteRunning 9876
    }

    It 'should allow https bindings' {
        Install-CIisWebsite -Name $script:siteName -Path $script:testDir -Bindings 'https/*:9876:','https://*:9443'
        (Test-CIisWebsite -Name $script:siteName) | Should -BeTrue
        $bindings = Get-CIisWebsite -Name $script:siteName | Select-Object -ExpandProperty Bindings
        $bindings[0].Protocol | Should -Be 'https'
        $bindings[1].Protocol | Should -Be 'https'
    }

    It 'should not recreate existing website' {
        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:testDir -Bindings 'http/*:9876:'
        $website = Get-CIisWebsite -Name $script:siteName
        $website | Should -Not -BeNullOrEmpty

        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:testDir -Bindings 'http/*:9876:'
        $Global:Error.Count | Should -Be 0
        $newWebsite = Get-CIisWebsite -Name $script:siteName
        $newWebsite | Should -Not -BeNullOrEmpty
        $newWebsite.Id | Should -Be $website.Id
    }

    It 'should change website settings' {
        $appPool = Install-CIisAppPool -Name 'CarbonShouldChangeWebsiteSettings' -PassThru
        $tempDir = New-CTempDirectory -Prefix $PSCommandPath

        try
        {
            Install-CIisWebsite -Name $script:siteName -PhysicalPath $PSScriptRoot
            $Global:Error.Count | Should -Be 0
            $website = Get-CIisWebsite -Name $script:siteName
            $website | Should -Not -BeNullOrEmpty
            $website.Name | Should -Be $script:siteName
            $website.PhysicalPath | Should -Be $PSScriptRoot

            Install-CIisWebsite -Name $script:siteName `
                                -PhysicalPath $tempDir `
                                -Bindings 'http/*:9986:' `
                                -ID 9986 `
                                -AppPoolName $appPool.Name
            $Global:Error.Count | Should -Be 0
            $website = Get-CIisWebsite -Name $script:siteName
            $website | Should -Not -BeNullOrEmpty
            $website.Name | Should -Be $script:siteName
            $website.PhysicalPath | Should -Be $tempDir.FullName
            $website.Id | Should -Be 9986
            $website.Applications[0].ApplicationPoolName | Should -Be $appPool.Name
            Assert-WebsiteBinding '[http] *:9986:'
        }
        finally
        {
            Uninstall-CIisAppPool -Name $appPool.Name
            Remove-Item -Path $tempDir -Recurse
        }
    }

    It 'should update bindings' {
        $output = Install-CIisWebsite -Name $script:siteName -PhysicalPath $PSScriptRoot
        $output | Should -BeNullOrEmpty

        Install-CIisWebsite -Name $script:siteName -Bindings 'http/*:8001:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8001:'
        Install-CIisWebsite -Name $script:siteName -Bindings 'http/*:8001:','http/*:8002:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8001:', '[http] *:8002:'
        Install-CIisWebsite -Name $script:siteName -Bindings 'http/*:8002:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8002:'
        Install-CIisWebsite -Name $script:siteName -Bindings 'http/*:8003:' -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding '[http] *:8003:'
    }

    It 'should return site object' {
        $site = Install-CIisWebsite -Name $script:siteName -PhysicalPath $PSScriptRoot -PassThru
        $site | Should -Not -BeNullOrEmpty
        $site | Should -BeOfType ([Microsoft.Web.Administration.Site])
        $site.Name | Should -Be $script:siteName
        $site.PhysicalPath | Should -Be $PSScriptRoot

        $site = Install-CIisWebsite -Name $script:siteName -PhysicalPath $PSScriptRoot
        $site | Should -BeNullOrEmpty
    }
}
