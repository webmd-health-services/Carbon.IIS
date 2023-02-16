
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

        $sitesToDelete = [Collections.Generic.List[String]]::New()
    }

    process
    {
        $sitesToDelete.AddRange($Name)
    }

    end
    {
        $madeChanges = $false

        $manager = Get-CIisServerManager

        foreach( $siteName in $sitesToDelete )
        {
            $site = $manager.Sites | Where-Object 'Name' -EQ $siteName
            if( -not $site )
            {
                return
            }

            $action = 'Remove IIS Website'
            if( $PSCmdlet.ShouldProcess($siteName, $action) )
            {
                Write-Information "Removing IIS website ""$($siteName)""."
                $manager.Sites.Remove( $site )
                $madeChanges = $true
            }
        }

        if( $madeChanges )
        {
            Save-CIisConfiguration
        }
    }
}
