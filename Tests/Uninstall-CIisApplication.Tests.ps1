
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

    function ThenApplication
    {
        param(
            [String] $AtVirtualPath,

            [switch] $Not,

            [switch] $Exists
        )

        Get-CIisApplication -SiteName $script:siteName -VirtualPath $AtVirtualPath |
            Should -Not:(-not $Not) -BeNullOrEmpty
    }

    function ThenFailed
    {
        param(
            [String] $WithErrorLike
        )

        $Global:Error | Should -BeLike $WithErrorLike
    }

    function WhenUninstalling
    {
        [CmdletBinding()]
        param(
            [String] $AppAtVirtualPath,
            [String] $UnderSite
        )

        if (-not $UnderSite)
        {
            $UnderSite = $script:siteName
        }

        Uninstall-CIisApplication -SiteName $UnderSite -VirtualPath $AppAtVirtualPath
    }
}

Describe 'Uninstall-CIisApplication' {
    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = Join-Path -Path $TestDrive -ChildPath $script:testNum
        $script:siteName = "Uninstall-CIisApplicatoin${script:testNum}"
        Install-CIisWebsite -Name $script:siteName -PhysicalPath $script:testDir
    }

    AfterEach {
        $script:testNum += 1
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'refuses to delete root application' {
        WhenUninstalling '/' -ErrorAction SilentlyContinue
        ThenFailed '*use the "Uninstall-CIisWebsite" function*'
        ThenApplication '/' -Exists
    }

    It 'deletes application in root' {
        GivenApplication '/rootapp'
        WhenUninstalling '/rootapp'
        ThenApplication '/rootapp' -Not -Exists
    }

    It 'deletes application way down the tree' {
        GivenApplication '/not/a/root/app'
        WhenUninstalling '/not/a/root/app'
        ThenApplication '/not/a/root/app' -Not -Exists
    }

    It 'is silent about non-existent application' {
        WhenUninstalling '/i/do/not/exist'
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'deletes multiple virtual directories' {
        GivenApplication '/app1'
        GivenApplication '/app2'
        GivenApplication '/thethird'
        WhenUninstalling '/app*' -UnderSite '*'
        ThenApplication '/app1' -Not -Exists
        ThenApplication '/app2' -Not -Exists
        ThenApplication '/thethird' -Exists
    }
}