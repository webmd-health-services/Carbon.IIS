
function Suspend-CIisAutoCommit
{
    <#
    .SYNOPSIS
    Stops Carbon.IIS functions from committing changes to IIS.

    .DESCRIPTION
    The `Suspend-CIisAutoCommit` functions stops Carbon.IIS functions from committing changes to IIS. Some IIS
    configuration is only committed correctly when an item is first saved/created. To ensure that all the changes made
    by Carbon.IIS are committed at the same time, call `Suspend-CIisAutoCommit`, make your changes, then call
    `Resume-CIisAutoCommit -Save` to start auto-committing again *and* to commit all uncomitted changes.

    .EXAMPLE
    Suspend-CIisAutoCommit

    Demonstrates how to call this function.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $script:skipCommit = $true
}