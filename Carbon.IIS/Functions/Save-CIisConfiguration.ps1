
function Save-CIisConfiguration
{
    <#
    .SYNOPSIS
    Saves configuration changes to IIS.

    .DESCRIPTION
    The `Save-CIisConfiguration` function saves changes made by Carbon.IIS functions or changes made on any object
    returned by any Carbon.IIS function. After making those changes, you must call `Save-CIisConfiguration` to save
    those changes to IIS.

    Carbon.IIS keeps an internal `Microsoft.Web.Administration.ServerManager` object that it uses to get all objects
    it operates on or returns to the user. `Save-CIisConfiguration` calls the `CommitChanges()` method on that
    Server Manager object.

    .EXAMPLE
    Save-CIIsConfiguration

    Demonstrates how to use this function.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Optional target object descripotion whose configuration will end up being saved. This is used as the target
        # when `-WhatIf` is true and calling `ShouldProcess(string target, string action)`.
        [String] $Target,

        # Optional action description to use when `-WhatIf` is used and calling
        # `ShouldProcess(string target, string action)`. Only used if `Target` is given.
        [String] $Action,

        # Optional message written to the information stream just before saving changes.
        [String] $Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $WhatIfPreference )
    {
        if( $Target )
        {
            $Target = $Target -replace '"', ''''
        }

        if( $Target -and $Action )
        {
            $PSCmdlet.ShouldProcess($Target, $Action) | Out-Null
        }

        if( $Target )
        {
            $PSCmdlet.ShouldProcess($Target) | Out-Null
        }

        Get-CIisServerManager -Reset | Out-Null
        return
    }

    if( $Message )
    {
        Write-Information $Message
    }

    Get-CIisServerManager -Commit | Out-Null
}