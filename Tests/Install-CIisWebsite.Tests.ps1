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

using namespace System.Diagnostics

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:siteName = $null
    $script:testDir = $null
    $script:siteNum = 0
    $script:appPoolName = $PSCommandPath | Split-Path -Leaf

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

        $site = Install-CIisWebsite -Name $script:siteName `
                                    -Path $script:testDir `
                                    -AppPoolName $script:appPoolName `
                                    @optionalParams
        $site | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
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
        $isRunning = $false
        $tryFor = [TimeSpan]'00:00:10'
        $timer = [Stopwatch]::StartNew()
        do
        {
            $website =
                [Microsoft.Web.Administration.ServerManager]::New().Sites | Where-Object 'Name' -eq $script:siteName

            try
            {
                $website.Start()
                $website.State | Should -Be 'Started'
                $isRunning = $true
                break
            }
            catch
            {
                Complete-W3ServiceTestFixture
                Write-Warning -Message ('Exception trying to start website "{0}": {1}' -f $script:siteName,$_)
                $Global:Error.Clear()
            }
            Start-Sleep -Milliseconds 100
        }
        while( $timer.Elapsed -lt $tryFor )

        $isRunning | Should -BeTrue
    }
}

Describe 'Install-CIisWebsite' {
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name $script:appPoolName
    }

    AfterAll {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = New-TestDirectory
        $script:siteName = "$($PSCommandPath | Split-Path -Leaf)-$($script:siteNum)"
        $script:siteNum += 1
        $script:port = Get-Port
        $script:homepage = [Guid]::NewGuid().ToString()
        $script:homepage | Set-Content -Path (Join-Path -Path $script:testDir -ChildPath 'index.html') -NoNewLine
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

        $anonymousAuthInfo = Get-CIisSecurityAuthentication -Anonymous -LocationPath $script:siteName
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
        Invoke-NewWebsite -Bindings "http/*:$($script:port):"
        Wait-ForWebsiteToBeRunning
        ThenUrlContent "http://localhost:$($script:port)/" -Is $script:homepage
    }

    It 'should create website with multiple bindings' {
        $port2 = Get-Port
        Invoke-NewWebsite -Bindings "http/*:$($script:port):", "http/*:$($port2):"
        Wait-ForWebsiteToBeRunning
        ThenUrlContent "http://localhost:$($script:port)/" -Is $script:homepage
        ThenUrlContent "http://localhost:$($port2)/" -Is $script:homepage
    }

    It 'should add site to custom app pool' {
        Install-CIisWebsite -Name $script:siteName -Path $script:testDir -AppPoolName $script:appPoolName
        $appPool = Get-CIisWebsite -Name $script:siteName
        $appPool = $appPool.Applications[0].ApplicationPoolName
        $appPool | Should -Be $script:appPoolName
    }

    It 'should update existing site' {
        Invoke-NewWebsite -Bindings "http/*:$(Get-Port):"
        $Global:Error | Should -BeNullOrEmpty
        Test-CIisWebsite -Name $script:siteName | Should -BeTrue
        Install-CIisVirtualDirectory -SiteName $script:siteName `
                                     -VirtualPath '/ShouldStillHangAround' `
                                     -PhysicalPath $PSScriptRoot

        Invoke-NewWebsite
        $Global:Error | Should -BeNullOrEmpty
        Test-CIisWebsite -Name $script:siteName | Should -BeTrue

        $website = Get-CIisWebsite -Name $script:siteName
        ($website.Applications[0].VirtualDirectories | Where-Object { $_.Path -eq '/ShouldStillHangAround' } ) |
            Should -Not -BeNullOrEmpty
    }

    It 'should create site directory' {
        $websitePath = Join-Path $script:testDir ShouldCreateSiteDirectory
        if( Test-Path $websitePath -PathType Container )
        {
            $null = Remove-Item $websitePath -Force
        }

        try
        {
            Install-CIisWebsite -Name $script:siteName -Path $websitePath -Bindings "http/*:$(Get-Port):" -AppPoolName $script:appPoolName
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
        Test-CIisWebsite -Name $script:siteName | Should -BeFalse
        $Global:Error | Should -Not -BeNullOrEmpty
        $Global:Error[0] | Should -Match 'bindings are invalid'
    }

    It 'should allow url bindings' {
        Invoke-NewWebsite -Bindings "http://*:$($port)"
        Test-CIisWebsite -Name $script:siteName | Should -BeTrue
        Wait-ForWebsiteToBeRunning
        ThenUrlContent "http://localhost:$($script:port)/" -Is $script:homepage
    }

    It 'should allow https bindings' {
        $port2 = Get-Port
        Install-CIisWebsite -Name $script:siteName `
                            -Path $script:testDir `
                            -Bindings "https/*:$($script:port):", "https://*:$($port2)"
        Test-CIisWebsite -Name $script:siteName | Should -BeTrue
        $bindings = Get-CIisWebsite -Name $script:siteName | Select-Object -ExpandProperty Bindings
        $bindings[0].Protocol | Should -Be 'https'
        $bindings[1].Protocol | Should -Be 'https'
    }

    It 'should not recreate existing website' {
        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:testDir -Bindings "http/*:$($script:port):"
        $website = Get-CIisWebsite -Name $script:siteName
        $website | Should -Not -BeNullOrEmpty

        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:testDir -Bindings "http/*:$($script:port):"
        $Global:Error | Should -BeNullOrEmpty
        $newWebsite = Get-CIisWebsite -Name $script:siteName
        $newWebsite | Should -Not -BeNullOrEmpty
        $newWebsite.Id | Should -Be $website.Id
    }

    It 'should change website settings' {
        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:testDir
        $Global:Error | Should -BeNullOrEmpty
        $website = Get-CIisWebsite -Name $script:siteName
        $website | Should -Not -BeNullOrEmpty
        $website.Name | Should -Be $script:siteName
        $website.PhysicalPath | Should -Be $script:testDir

        $newWebRoot = New-TestDirectory
        Install-CIisWebsite -Name $script:siteName `
                            -PhysicalPath $newWebRoot `
                            -Bindings "http/*:$($script:port):" `
                            -ID $script:port `
                            -AppPoolName $script:appPoolName
        $Global:Error | Should -BeNullOrEmpty
        $website = Get-CIisWebsite -Name $script:siteName
        $website | Should -Not -BeNullOrEmpty
        $website.Name | Should -Be $script:siteName
        $website.PhysicalPath | Should -Be $newWebRoot
        $website.Id | Should -Be $script:port
        $website.Applications[0].ApplicationPoolName | Should -Be $script:appPoolName
        Assert-WebsiteBinding "[http] *:$($script:port):"
    }

    It 'should update bindings' {
        $output = Install-CIisWebsite -Name $script:siteName -PhysicalPath $PSScriptRoot
        $output | Should -BeNullOrEmpty

        Install-CIisWebsite -Name $script:siteName -Bindings "http/*:$($script:port):" -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding "[http] *:$($script:port):"
        $port2 = Get-Port
        Install-CIisWebsite -Name $script:siteName `
                            -Bindings "http/*:$($script:port):","http/*:$($port2):" `
                            -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding "[http] *:$($script:port):", "[http] *:$($port2):"
        Install-CIisWebsite -Name $script:siteName -Bindings "http/*:$($port2):" -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding "[http] *:$($port2):"
        $port3 = Get-Port
        Install-CIisWebsite -Name $script:siteName -Bindings "http/*:$($port3):" -PhysicalPath $PSScriptRoot
        Assert-WebsiteBinding "[http] *:$($port3):"
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
