
function New-CIisServerManager
{
    <#
    .SYNOPSIS
    Returns a new instance of the `Microsoft.Web.Administration.ServerManager` class.

    .DESCRIPTION
    The `New-CIisServerManager` function returns a new instance of the `Microsoft.Web.Administration.SiteManager` class.
    This class uses native OS resources, so when you're done using it, you should call its `Dispose()` method.

    .EXAMPLE
    $mgr = New-CIisServerManager

    Demonstrates how to get a new `Microsoft.Web.Administration.ServerManager` object.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return [Microsoft.Web.Administration.ServerManager]::New()
}