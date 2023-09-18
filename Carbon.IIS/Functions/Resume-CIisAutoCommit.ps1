
function Resume-CIisAutoCommit
{
    <#
    .SYNOPSIS
    Starts Carbon.IIS functions committing changes to IIS.

    .DESCRIPTION
    The `Resume-CIisAutoCommit` functions starts Carbon.IIS functions committing changes to IIS. Some IIS configuration
    is only committed correctly when an item is first saved/created. To ensure that all the changes made by Carbon.IIS
    are committed at the same time, call `Suspend-CIisAutoCommit`, make your changes, then call `Resume-CIisAutoCommit
    -Save` to start auto-committing again *and* to commit all uncomitted changes.

    .EXAMPLE
    Resume-CIisAutoCommit -Save

    Demonstrates how to call this function to both start auto-committing changes again *and* to save any uncommitted
    changes.

    .EXAMPLE
    Resume-CIisAutoCommit

    Demonstrates how to call this function to start auto-committing changes but not to save any uncommitted changes and
    leave them pending in memory.
    #>
    [CmdletBinding()]
    param(
        # When set, will save any uncommitted changes.
        [switch] $Save
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $script:skipCommit = $false

    if (-not $Save)
    {
        return
    }

    Save-CIisConfiguration
}
