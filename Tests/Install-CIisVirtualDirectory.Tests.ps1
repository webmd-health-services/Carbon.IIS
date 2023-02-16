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
    $script:port = 0
    $script:appPoolName = $PSCommandPath | Split-Path -Leaf
    $script:siteName = ''
    $script:vDirName = 'VDir'
    $script:webConfig = $null
    $script:output = $null
    $script:testNum = 0

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    function GivenApplication
    {
        param(
            [String] $Named,

            [String] $ServedFrom
        )

        Install-CIisApplication -SiteName $script:siteName `
                                -VirtualPath $Named `
                                -PhysicalPath (Join-Path -Path $script:vDirsRoot -ChildPath $ServedFrom) `
                                -AppPoolName $script:appPoolName
    }

    function GivenDirectory
    {
        param(
            [String] $Named
        )

        $path = Join-Path -Path $script:vDirsRoot -ChildPath $Named
        New-Item -Path $path -ItemType 'Directory'

        $indexPath = Join-Path -Path $path -ChildPath 'index.html'
        $path | Set-Content -Path $indexPath -NoNewline
    }

    function ThenNoOutput
    {
        $script:output | Should -BeNullOrEmpty
    }

    function WhenInstalling
    {
        param(
            [hashtable] $WithArguments
        )

        if( $WithARguments.ContainsKey('PhysicalPath') )
        {
            $WithArguments['PhysicalPath'] = Join-Path -Path $script:vDirsRoot -ChildPath $WithArguments['PhysicalPath']
        }

        $script:output = Install-CIisVirtualDirectory -SiteName $script:siteName @WithArguments
    }

    function ThenRunning
    {
        param(
            [Parameter(Mandatory)]
            [String] $VirtualPath,

            [Parameter(Mandatory)]
            [String] $From,

            [String] $UnderApplication = '/'
        )

        $script:webConfig | Should -Not -Exist

        $script:output | Should -BeNullOrEmpty

        $vDirPhysicalPath = Join-Path -Path $script:vDirsRoot -ChildPath $From

        $urlPath = Join-CIisPath -Path $UnderApplication, $VirtualPath
        ThenUrlContent "http://localhost:$($script:port)/$($urlPath)/" -Is $vDirPhysicalPath

        $website = Get-CIisWebsite -Name $script:siteName
        $website.Applications |
            Where-Object 'Path' -eq $UnderApplication |
            Select-Object -ExpandProperty 'VirtualDirectories' |
            Where-Object 'physicalPath' -EQ $vDirPhysicalPath |
            Select-Object -ExpandProperty 'Path' |
            Should -Be "/$($VirtualPath)"
    }
}

Describe 'Install-CIisVirtualDirectory' {
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name $script:appPoolName
        # We create the directory outside the webroot to ensure vdir actually gets created. If we create under the
        # website root, there's no difference between a vdir and a regular directory.
        $script:vDirsRoot = New-TestDirectory
    }

    AfterAll {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
        $script:port = New-Port
        $script:siteName = "$($PSCommandPath | Split-Path -Leaf)$($script:testNum)"
        $script:testNum += 1
        Install-CIisWebsite -Name $script:siteName `
                            -Path $script:testDir `
                            -Bindings "http://*:$($script:port)" `
                            -AppPoolName $script:appPoolName
        $script:webConfig = Join-Path -Path $script:testDir -ChildPath 'web.config'
        if( Test-Path -Path $script:webConfig )
        {
            Remove-Item -Path $script:webConfig
        }
        $script:output = $null
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should create virtual directory' {
        GivenDirectory 'One'
        WhenInstalling -WithArguments @{ 'VirtualPath' = 'VOne' ; 'PhysicalPath' = 'One' }
        ThenNoOutput
        ThenRunning 'VOne' -From 'One'
    }

    It 'should handle extra directory separator character' {
        GivenDirectory 'Two'
        WhenInstalling -WithArguments @{ 'VirtualPath' = 'VTwo' ; 'PhysicalPath' = 'Two'}
        ThenNoOutput
        ThenRunning 'VTwo' -From 'Two'
    }

    It 'should update physical path' {
        GivenDirectory 'ThreeA'
        GivenDirectory 'ThreeB'
        WhenInstalling -WithArguments @{ 'VirtualPath' = 'VThree' ; 'PhysicalPath' = 'ThreeA' }
        ThenRunning 'VThree' -From 'ThreeA'
        WhenInstalling -WithArguments @{ 'VirtualPath' = 'VThree' ; 'PhysicalPath' = 'ThreeB' }
        ThenRunning 'VThree' -From 'ThreeB'
    }

    It 'should create double vitual directory' {
        GivenDirectory 'Four'
        WhenInstalling -WithArguments @{ 'VirtualPath' = 'VFour/VFour' ; 'PhysicalPath' = 'Four' }
        ThenRunning 'VFour/VFour' -From 'Four'
    }

    It 'should delete if forced' {
        GivenDirectory 'Five'
        WhenInstalling -WithArguments @{ 'VirtualPath' = 'VFive' ; 'PhysicalPath' = 'Five' }

        $app = Get-CIisApplication -SiteName $script:siteName
        $vdir = $app.VirtualDirectories['/VFive']
        $vdir | Should -Not -BeNullOrEmpty

        $defaultLogonMethod = $vdir.LogonMethod
        $defaultLogonMethod | Should -Not -Be 2
        $vdir.LogonMethod = 2
        Save-CIIsConfiguration

        WhenInstalling -WithArguments @{ 'VirtualPath' = 'VFive' ; 'PhysicalPath' = 'Five'; 'Force' = $true }

        $app = Get-CIisApplication -SiteName $script:siteName
        $vdir = $app.VirtualDirectories['/VFive']
        $vdir.LogonMethod | Should -Be $defaultLogonMethod
    }

    It 'should create a virtual directory under an application' {
        GivenDirectory 'Six'
        GivenDirectory 'Seven'
        GivenApplication -Named 'ASix' -ServedFrom 'Six'
        WhenInstalling -WithArguments @{
            'ApplicationPath' = 'ASix';
            'VirtualPath' = 'VSeven';
            'PhysicalPath' = 'Seven'
        }
        ThenRunning -UnderApplication '/ASix' 'VSeven' -From 'Seven'
    }
}
