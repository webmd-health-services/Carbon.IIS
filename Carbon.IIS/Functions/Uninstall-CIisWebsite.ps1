
function Uninstall-CIisWebsite
{
    <#
    .SYNOPSIS
    Removes a website

    .DESCRIPTION
    Pretty simple: removes the website named `Name`.  If no website with that name exists, nothing happens.

    Beginning with Carbon 2.0.1, this function is not available if IIS isn't installed.

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
    [CmdletBinding()]
    param(
        # The name or ID of the website to remove.
        [Parameter(Mandatory, Position=0)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( Test-CIisWebsite -Name $Name )
    {
        $manager = New-CIisServerManager
        try
        {
            $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
            $manager.Sites.Remove( $site )
            $manager.CommitChanges()
        }
        finally
        {
            $manager.Dispose()
        }
    }
}
