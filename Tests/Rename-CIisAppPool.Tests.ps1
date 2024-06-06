
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    function GivenAppPool
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $Named
        )

        Install-CIisAppPool -Name $Named
    }

    function ThenAppPool
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $Named,

            [switch] $Not,

            [Parameter(Mandatory)]
            [switch] $Exists
        )

        $mgr = [Microsoft.Web.Administration.ServerManager]::New()
        $appPool = $mgr.ApplicationPools | Where-Object 'name' -EQ $Named
        if ($Not -and $Exists)
        {
            $appPool | Should -BeNullOrEmpty
        }
        elseif ($Exists)
        {
            $appPool | Should -Not -BeNullOrEmpty
        }
    }

    function WhenRenaming
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $AppPool,

            [Parameter(Mandatory)]
            [String] $To
        )

        Rename-CIisAppPool -Name $AppPool -NewName $To
    }
}

Describe 'Rename-CIisAppPool' {
    BeforeEach {
        Uninstall-CIisAppPool 'oldname*'
        Uninstall-CIisAppPool 'newname*'
        Uninstall-CIisWebsite 'oldname*'
        $Global:Error.Clear()
    }

    It 'renames an existing app pool' {
        GivenAppPool 'oldname1'
        WhenRenaming 'oldname1' -To 'newname1'
        ThenAppPool 'newname1' -Exists
        ThenAppPool 'oldname1' -Not -Exists
    }

    It 'supports wildcard name' {
        GivenAppPool 'oldname2'
        WhenRenaming 'oldname*' -To 'newname2'
        ThenAppPool 'newname2' -Exists
        ThenAppPool 'oldname2' -Not -Exists
    }

    It 'fails when wildcard matches multiple app pools' {
        GivenAppPool 'oldname3'
        GivenAppPool 'oldname4'
        WhenRenaming 'oldname*' -To 'newname3' -ErrorAction SilentlyContinue
        $Global:Error | Should -Match '2 application pools that match that name'
        ThenAppPool 'oldname3' -Exists
        ThenAppPool 'oldname4' -Exists
        ThenAppPool 'newname2' -Not -Exists
    }

    It 'fails when app pool in use' {
        GivenAppPool 'oldname5'
        Install-CIisWebsite -Name 'oldname5' -PhysicalPath $TestDrive -AppPoolName 'oldname5'
        WhenRenaming 'oldname5' -To 'newname5' -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'it is assigned to 1 application'
        ThenAppPool 'oldname5' -Exists
        ThenAppPool 'newname5' -Not -Exists
    }
}
