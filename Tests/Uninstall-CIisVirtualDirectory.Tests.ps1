
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:testDir = ''
    $script:testNum = 0
    $script:siteName = ''

    function GivenApplication
    {
        param(
            [String] $AtVirtualPath
        )

        Install-CIisApplication -SiteName $script:siteName -VirtualPath $AtVirtualPath -PhysicalPath $script:testDir
    }

    function GivenVirtualDirectory
    {
        param(
            [String] $AtVirtualPath,

            [String] $UnderApplication
        )

        $installArgs = @{}
        if ($UnderApplication)
        {
            $installArgs['ApplicationPath'] = $UnderApplication
        }

        Install-CIisVirtualDirectory -SiteName $script:siteName `
                                     -VirtualPath $AtVirtualPath `
                                     -PhysicalPath $script:testDir `
                                     @installArgs
    }

    function ThenNoError
    {
        $Global:Error | Should -BeNullOrEmpty
    }

    function ThenFailed
    {
        param(
            [String] $WithErrorLike
        )

        $Global:Error | Should -BeLike $WithErrorLike
    }

    function ThenVirtualDirectory
    {
        param(
            [String] $AtVirtualPath,

            [String] $UnderApplication,

            [switch] $Not,

            [switch] $Exists
        )

        $getArgs = @{}
        if ($UnderApplication)
        {
            $getArgs['ApplicationPath'] = $UnderApplication
        }

        $vdir = Get-CIisVirtualDirectory -SiteName $script:siteName -VirtualPath $AtVirtualPath @getArgs -ErrorAction Ignore

        if ($Not)
        {
            $vdir | Should -BeNullOrEmpty
        }
        else
        {
            $vdir | Should -Not -BeNullOrEmpty
        }
    }

    function WhenUninstalling
    {
        [CmdletBinding()]
        param(
            [String] $VirtualDirectoryAt,

            [String] $UnderApplication,

            [String] $UnderSite
        )

        if (-not $UnderSite)
        {
            $UnderSite = $script:siteName
        }

        $uninstallArgs = @{}
        if ($UnderApplication)
        {
            $uninstallArgs['ApplicationPath'] = $UnderApplication
        }

        Uninstall-CIisVirtualDirectory -SiteName $UnderSite -VirtualPath $VirtualDirectoryAt @uninstallArgs
    }
}

Describe 'Uninstall-CIisVirtualDirectory' {
    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = Join-Path -Path $TestDrive -ChildPath $script:testNum
        $script:siteName = "Uninstall-CIisVirtualDirectory${script:testNum}"
        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:testDir
    }

    AfterEach {
        $script:testNum += 1
        Uninstall-CIisWebsite -Name $script:siteName
    }

    Context 'under site' {
        It 'refuses to delete root virtual directory' {
            WhenUninstalling '/' -ErrorAction SilentlyContinue
            ThenFailed '*use the "Uninstall-CIisWebsite" function*'
            ThenVirtualDirectory '/' -Exists
        }

        It 'deletes virtual directory in root' {
            GivenVirtualDirectory '/rootvdir'
            WhenUninstalling '/rootvdir'
            ThenNoError
            ThenVirtualDirectory '/rootvdir' -Not -Exists
        }

        It 'deletes virtual directory way down the tree' {
            GivenVirtualDirectory '/not/a/root/vdir'
            WhenUninstalling '/not/a/root/vdir'
            ThenNoError
            ThenVirtualDirectory '/not/a/root/vdir' -Not -Exists
        }

        It 'is silent about non-existent virtual directory' {
            WhenUninstalling '/i/do/not/exist'
            ThenNoError
        }
    }

    Context 'under application' {
        It 'refuses to delete root virtual directory' {
            GivenApplication 'parent'
            WhenUninstalling '/' -UnderApplication 'parent' -ErrorAction SilentlyContinue
            ThenFailed '*use the "Uninstall-CIisApplication" function*'
            ThenVirtualDirectory '/' -UnderApplication 'parent' -Exists
        }

        It 'deletes virtual directory in root' {
            GivenApplication 'parent'
            GivenVirtualDirectory '/rootvdir'
            WhenUninstalling '/rootvdir' -UnderApplication 'parent'
            ThenNoError
            ThenVirtualDirectory '/rootvdir' -UnderApplication 'parent' -Not -Exists
        }

        It 'deletes virtual directory way down the tree' {
            GivenApplication 'parent'
            GivenVirtualDirectory '/not/a/root/vdir' -UnderApplication 'parent'
            WhenUninstalling '/not/a/root/vdir' -UnderApplication 'parent'
            ThenNoError
            ThenVirtualDirectory '/not/a/root/vdir' -UnderApplication 'parent' -Not -Exists
        }

        It 'is silent about non-existent virtual directory' {
            GivenApplication 'parent'
            WhenUninstalling '/i/do/not/exist' -UnderApplication 'parent'
            ThenNoError
        }
    }

    It 'deletes multiple virtual directories' {
        GivenApplication '/app1'
        GivenVirtualDirectory '/vdir1' -UnderApplication 'app1'
        GivenApplication '/app2'
        GivenVirtualDirectory '/vdir2' -UnderApplication 'app2'
        GivenApplication '/thethird'
        GivenVirtualDirectory '/vdir3' -UnderApplication 'thethird'
        WhenUninstalling '/vdir*' -UnderApplication 'app*' -UnderSite '*'
        ThenVirtualDirectory '/vdir1' -UnderApplication 'app1' -Not -Exists
        ThenVirtualDirectory '/vdir2' -UnderApplication 'app2' -Not -Exists
        ThenVirtualDirectory '/vdir3' -UnderApplication 'thethird' -Exists
    }
}