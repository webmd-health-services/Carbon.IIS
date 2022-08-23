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
    Write-Debug 'BeforeAll'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:port = 9878
    $script:siteName = 'TestApplication'
    $script:appName = 'App'
    $script:appPoolName = 'TestApplication'

    function GivenDirectory
    {
        param(
            [String] $Named,

            [String] $WithContent = $script:appIndexHtmlContent
        )

        $path = Join-Path -Path $TestDrive -ChildPath $Named
        if( -not (Test-Path -Path $path) )
        {
            New-Item -Path $path -ItemType 'Directory'
        }

        if( $WithContent )
        {
            $WithContent | Set-Content -Path (Join-Path -Path $path -ChildPath 'index.html') -NoNewline
        }
    }

    function Test-ShouldNotReturnAnything($Path = $script:testDir)
    {
        $result = Install-CIisApplication -SiteName $script:siteName -VirtualPath $script:appName -PhysicalPath $Path
        $Global:Error.Count | Should -Be 0
        $result | Should -BeNullOrEmpty
        $result =
            Install-CIisApplication -SiteName $script:siteName -VirtualPath $script:appName -PhysicalPath $env:TEMP
        $Global:Error.Count | Should -Be 0
        $result | Should -BeNullOrEmpty
    }

    function ThenAppExists
    {
        $app = Get-CIisApplication -SiteName $script:siteName -VirtualPath $script:appName
        $app | Should -Not -BeNullOrEmpty
        $app.ApplicationPoolName | Should -Be $script:appPoolName
    }

    function ThenAppRunning
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $VirtualPath,

            [String] $ExpectedContent = $script:appIndexHtmlContent
        )

        ThenUrlContent "http://localhost:$($script:port)/$($VirtualPath)/" -Is $ExpectedContent
    }

    function ThenPhysicalPathIs
    {
        param(
            [String] $ExpectedPath
        )

        $ExpectedPath = Join-Path -Path $script:testDir -ChildPath $ExpectedPath
        $ExpectedPath = [IO.Path]::GetFullPath($ExpectedPath)
        $physicalPath = Get-CIisApplication -SiteName $script:siteName -VirtualPath $script:appName |
                            Select-Object -ExpandProperty 'PhysicalPath'
        $physicalPath | Should -Be $ExpectedPath
    }

    function WhenInstalling
    {
        param(
            [String] $Path
        )

        if( $Path )
        {
            $Path = Join-Path -Path $script:testDir -ChildPath $Path
        }
        else
        {
            $Path = $script:testDir
        }

        $Global:Error.Clear()
        $result = Install-CIisApplication -SiteName $script:siteName `
                                          -VirtualPath $script:appName `
                                          -PhysicalPath $Path `
                                          -AppPoolName $script:appPoolName `
                                          -PassThru
        $Global:Error | Should -BeNullOrEmpty
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeOfType ([Microsoft.Web.Administration.Application])
        $script:webConfigPath | Should -Not -Exist
    }
}

Describe 'Install-CIisApplication' {
    BeforeAll {
        Write-Debug 'BeforeAll'
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name $script:appPoolName
        Install-CIisAppPool -Name 'DefaultAppPool'
        $script:websiteRoot = New-TestDirectory
        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:websiteRoot -Bindings "http://*:$($script:port)"
    }

    AfterAll {
        Write-Debug 'AfterAll'
        Uninstall-CIisWebsite -Name $script:siteName
        Uninstall-CIisAppPool -Name $script:appPoolName
        Uninstall-CIisAppPool -Name 'DefaultAppPool'
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        Write-Debug 'BeforeEach'
        $script:testDir = New-TestDirectory

        $script:appIndexHtmlContent = [Guid]::NewGuid().ToString()
        $script:appIndexHtmlContent |
            Set-Content -Path (Join-Path -Path $script:testDir -ChildPath 'index.html') -NoNewLine

        foreach( $path in @($script:websiteRoot, $script:testDir) )
        {
            $script:webConfigPath = Join-Path -Path $path -ChildPath 'web.config'
            if( Test-Path $script:webConfigPath )
            {
                Remove-Item $script:webConfigPath
            }
        }

        $Global:Error.Clear()
        Write-Debug 'It'
    }

    AfterEach {
        Write-Debug 'AfterEach'
        $deletedSomething = $false
        Get-CIisApplication -SiteName $script:siteName |
            Where-Object 'Path' -ne '/' |
            ForEach-Object { $_.Delete() ; $deletedSomething = $true }
        if( $deletedSomething )
        {
            Save-CIisConfiguration
        }
        Complete-W3ServiceTestFixture
    }

    It 'should create application' {
        WhenInstalling
        ThenAppRunning $script:appName
        ThenAppExists
        ThenPhysicalPathIs '.'
    }

    It 'should resolve application physical path' {
        GivenDirectory 'FubarSnafu' -WithContent 'One'
        WhenInstalling -Path  '..\FubarSnafu'
        ThenPhysicalPathIs '..\FubarSnafu'
    }

    It 'should change path of existing application' {
        GivenDirectory 'Two' -WithContent 'Two'
        GivenDirectory 'Three' -WithContent 'Three'
        WhenInstalling -Path '..\Two'
        ThenAppExists
        ThenPhysicalPathIs '..\Two'

        WhenInstalling -Path '..\Three'
        ThenAppExists
        ThenPhysicalPathIs '..\Three'
    }

    It 'should update application pool' {
        $result = Install-CIisApplication -SiteName $script:siteName `
                                          -VirtualPath $script:appName `
                                          -PhysicalPath $script:testDir `
                                          -AppPoolName $script:appPoolName `
                                          -PassThru
        $Global:Error | Should -BeNullOrEmpty
        $result | Should -Not -BeNullOrEmpty
        $result.ApplicationPoolName | Should -Be $script:appPoolName
        ThenAppRunning $script:appName

        $result = Install-CIisApplication -SiteName $script:siteName `
                                          -VirtualPath $script:appName `
                                          -PhysicalPath $script:testDir `
                                          -AppPoolName 'DefaultAppPool' `
                                          -PassThru
        $Global:Error | Should -BeNullOrEmpty
        $result | Should -Not -BeNullOrEmpty
        $result.ApplicationPoolName | Should -Be 'DefaultAppPool'

        $result = Install-CIisApplication -SiteName $script:siteName `
                                          -VirtualPath $script:appName `
                                          -PhysicalPath $script:testDir `
                                          -PassThru
        $Global:Error | Should -BeNullOrEmpty
        $result | Should -Not -BeNullOrEmpty
        $result.ApplicationPoolName | Should -Be 'DefaultAppPool'
    }

    It 'should create application directory' {
        $appDir = Join-Path $script:testDir 'ApplicationDirectory'
        if( Test-Path $appDir -PathType Container )
        {
            Remove-Item $appDir -Force
        }

        try
        {
            $result = WhenInstalling -Path 'ApplicationDirectory'
            $result | Should -BeNullOrEmpty
            $appDir | Should -Exist
        }
        finally
        {
            if( Test-Path $appDir -PathType Container )
            {
                Remove-Item $appDir -Force
            }
        }
    }
}
