
BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    function GivenWebsiteWithLocationConfiguration
    {
        [CmdletBinding()]
        param(
            [String] $Named
        )
        Install-CIisWebsite -Name $Named `
                            -PhysicalPath $script:testDir `
                            -Binding 'http/*:80:removeconfiglocationone.localhost'
        Set-CIisHttpHeader -SiteName $Named -Name 'X-Carbon.IIS-RemoveConfigLocation' -Value $Named
        Get-CIisConfigurationLocationPath -LocationPath $Named | Should -Not -BeNullOrEmpty
    }

    function GivenVirtualPathWithLocationConfiguration
    {
        [CmdletBinding()]
        param(
            [String] $VirtualPath,

            [String] $UnderSite
        )
        Set-CIisHttpHeader -LocationPath ($UnderSite, $VirtualPath | Join-CIisVirtualPath) `
                           -Name 'X-Carbon.IIS-RemoveConfigLocation-VirtualPath' `
                           -Value "$($UnderSite)/$($VirtualPath)"
        Get-CIisConfigurationLocationPath -LocationPath "$($UnderSite)/$($VirtualPath)" | Should -Not -BeNullOrEmpty
    }

    function WhenRemoving
    {
        [CmdletBinding()]
        param(
            [hashtable] $WithArgs
        )

        $script:timeBeforeRemove = Get-Date
        # AppVeyor builds can sometimes run *really* fast.
        Start-Sleep -Milliseconds 5
        Remove-CIisConfigurationLocation @WithArgs
    }

    function ThenLocation
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $ForSite,

            [String] $AndVirtualPath,

            [switch] $Not,

            [Parameter(Mandatory, ParameterSetName='Exists')]
            [switch] $Exists
        )

        Get-CIisConfigurationLocationPath -LocationPath "$($ForSite)/$($AndVirtualPath)" |
            Should -Not:(-not $Not) -BeNullOrEmpty
    }
}

Describe 'Remove-CIisConfigurationLocation' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = New-TestDirectory
    }

    AfterEach {
        Get-CIisWebsite | Where-Object 'Name' -Like 'RemoveConfigLocation*' | Uninstall-CIisWebsite
    }

    It 'should write an error when location does not exist' {
        WhenRemoving -WithArgs @{ SiteName = 'fubar' ; ErrorAction = 'SilentlyContinue' }
        ThenError -Matches 'location "fubar" does not exist'
        ThenAppHostConfig -Not -ModifiedSince $script:timeBeforeRemove
    }

    It 'should not write an error when location does not exist' {
        WhenRemoving -WithArgs @{ SiteName = 'fubar' ; ErrorAction = 'Ignore' }
        ThenError -Empty
        ThenAppHostConfig -Not -ModifiedSince $script:timeBeforeRemove
    }

    It 'should remove configuration location' {
        $siteName = 'RemoveConfigLocationOne'
        GivenWebsiteWithLocationConfiguration $siteName
        WhenRemoving -WithArgs @{ SiteName = $siteName }
        ThenLocation -ForSite $siteName -Not -Exists
        ThenAppHostConfig -ModifiedSince $script:timeBeforeRemove
    }

    It 'should remove configuration location for virtual path' {
        $siteName = 'RemoveConfigLocationTwo'
        $virtualPath = 'some/virtual/path'
        GivenWebsiteWithLocationConfiguration $siteName
        GivenVirtualPathWithLocationConfiguration $virtualPath -UnderSite $siteName
        WhenRemoving -WithArgs @{ SiteName = $siteName ; VirtualPath = $virtualPath }
        ThenLocation -ForSite $siteName -Exists
        ThenLocation -ForSite $siteName -AndVirtualPath $virtualPath -Not -Exists
        ThenAppHostConfig -ModifiedSince $script:timeBeforeRemove
    }

    It 'should support whatif' {
        $siteName = 'RemoveConfigLocationThree'
        GivenWebsiteWithLocationConfiguration $siteName
        WhenRemoving -WithArgs @{ SiteName = $siteName ; WhatIf = $true }
        ThenLocation -ForSite $siteName -Exists
        ThenAppHostConfig -Not -ModifiedSince $script:timeBeforeRemove
    }
}