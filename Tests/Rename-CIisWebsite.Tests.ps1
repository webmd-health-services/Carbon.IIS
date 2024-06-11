
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    function GivenWebsite
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $Named
        )

        Install-CIisWebsite -Name $Named -PhysicalPath $TestDrive
    }

    function ThenWebsite
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $Named,

            [switch] $Not,

            [Parameter(Mandatory)]
            [switch] $Exists
        )

        $mgr = [Microsoft.Web.Administration.ServerManager]::New()
        $website = $mgr.Sites | Where-Object 'name' -EQ $Named
        if ($Not -and $Exists)
        {
            $website | Should -BeNullOrEmpty
        }
        elseif ($Exists)
        {
            $website | Should -Not -BeNullOrEmpty
        }
    }

    function WhenRenaming
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $Website,

            [Parameter(Mandatory)]
            [String] $To
        )

        Rename-CIisWebsite -Name $Website -NewName $To
    }
}

Describe 'Rename-CIisWebsite' {
    BeforeEach {
        $sitesToDelete = & {
            Get-CIisWebsite -Name 'oldname*' | Select-Object -ExpandProperty 'name' | Write-Output
            Get-CIisWebsite -Name 'newname*' | Select-Object -ExpandProperty 'name' | Write-Output
        }
        if ($sitesToDelete)
        {
            Uninstall-CIisWebsite -Name $sitesToDelete
        }
        $Global:Error.Clear()
    }

    It 'renames an existing website' {
        GivenWebsite 'oldname1'
        WhenRenaming 'oldname1' -To 'newname1'
        ThenWebsite 'newname1' -Exists
        ThenWebsite 'oldname1' -Not -Exists
    }

    It 'supports wildcard name' {
        GivenWebsite 'oldname2'
        WhenRenaming 'oldname*' -To 'newname2'
        ThenWebsite 'newname2' -Exists
        ThenWebsite 'oldname2' -Not -Exists
    }

    It 'fails when wildcard matches multiple websites' {
        GivenWebsite 'oldname3'
        GivenWebsite 'oldname4'
        WhenRenaming 'oldname*' -To 'newname3' -ErrorAction SilentlyContinue
        $Global:Error | Should -Match '2 websites that match that name'
        ThenWebsite 'oldname3' -Exists
        ThenWebsite 'oldname4' -Exists
        ThenWebsite 'newname2' -Not -Exists
    }
}
