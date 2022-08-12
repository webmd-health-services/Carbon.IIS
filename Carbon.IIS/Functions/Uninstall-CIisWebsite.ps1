
function Uninstall-CIisWebsite
{
    <#
    .SYNOPSIS
    Removes a website

    .DESCRIPTION
    Pretty simple: removes the website named `Name`. If no website with that name exists, nothing happens.

    .LINK
    Get-CIisWebsite

    .LINK
    Install-CIisWebsite

    .EXAMPLE
    Uninstall-CIisWebsite -Name 'MyWebsite'

    Removes MyWebsite.

    .EXAMPLE
    Uninstall-CIisWebsite 1

    Removes the website whose ID is 1.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name or ID of the website to remove.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String[]] $Name
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $manager = New-CIisServerManager

        $commitChanges = $false
    }

    process
    {
        foreach( $nameItem in $Name )
        {
            $site = $manager.Sites | Where-Object 'Name' -EQ $nameItem
            if( -not $site )
            {
                return
            }

            $action = 'Remove IIS Website'
            if( $PSCmdlet.ShouldProcess($nameItem, $action) )
            {
                Write-Information "Removing IIS website ""$($nameItem)""."
                $manager.Sites.Remove( $site )
                $commitChanges = $true
            }
        }
    }

    end
    {
        try
        {
            if( $commitChanges )
            {
                $manager.CommitChanges()
            }
        }
        finally
        {
            $manager.Dispose()
        }
    }
}
