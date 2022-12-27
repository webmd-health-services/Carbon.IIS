
function Reset-CIisServerManager
{
    <#
    .SYNOPSIS
    Disposes the current Server Manager object and creates a new one.

    .DESCRIPTION
    The `Reset-CIisServerManager` function disposes the current `Microsoft.Web.Administration.ServerManager` object that
    the Carbon.IIS module uses internally, and creates a new one. If you want to make sure you're getting the latest
    IIS state, call this function before calling other Carbon.IIS functions.

    .EXAMPLE
    Reset-CIisServerManager

    Demonstrates how to use this function.
    #>
    [CmdletBinding()]
    param(
    )

    Get-CIisServerManager -Reset | Out-Null
}
