
function Get-CIisServerManager
{
    <#
    .SYNOPSIS
    Returns the current instance of the `Microsoft.Web.Administration.ServerManager` class.

    .DESCRIPTION
    The `Get-CIisServerManager` function returns the current instance of `Microsoft.Web.Administration.ServerManager`
    that the Carbon.IIS module is using. After saving committing changes, the current server manager is destroyed (i.e.
    its `Dispose` method is called). In case the current server manager is destroyed, `Get-CIisServerManager` will
    create a new instance of the `Microsoft.Web.Administration.SiteManager` class.

    After using the server manager, if you've made any changes to any objects referenced from it, call the
    `Save-CIisConfiguration` function to save/commit your changes. This will properly destroy the server manager after
    saving/committing your changes.

    .EXAMPLE
    $mgr = Get-CIisServerManager

    Demonstrates how to get the instance of the `Microsoft.Web.Administration.ServerManager` class the Carbon.IIS
    module is using.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $msgPrefix = "ServerManager  #"

    # It's been disposed.
    if( -not $script:serverMgr.ApplicationPoolDefaults )
    {
        $script:serverMgr = [Microsoft.Web.Administration.ServerManager]::New()
        Write-Debug "$($msgPrefix)$('{0,-10}' -f $script:serverMgr.GetHashCode())  New()"
    }
    Write-Debug "$($msgPrefix)$('{0,-10}' -f $script:serverMgr.GetHashCode())"
    return $script:serverMgr
}