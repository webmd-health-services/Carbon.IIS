
function Rename-CIisWebsite
{
    <#
    .SYNOPSIS
    Renames an IIS website.

    .DESCRIPTION
    The `Rename-CIisWebsite` function renames an IIS website. Pass the name of the website to the `Name` parameter.
    Wildcards are permitted if the pattern only matches one website. Pass the new name of the website to the `NewName`
    parameter.

    If the website does not exist, the function writes an error and does nothing.

    .EXAMPLE
    Rename-CIisWebsite -Name 'OldName' -NewName 'NewName'

    Demonstrates how to rename an IIS application with name "OldName" to "NewName".
    #>
    [CmdletBinding()]
    param(
        # The name of the website to rename.
        [Parameter(Mandatory)]
        [String] $Name,

        # The website's new name.
        [Parameter(Mandatory)]
        [String] $NewName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $Name

    if (-not $site)
    {
        return
    }

    $siteCount = ($site | Measure-Object).Count
    if ($siteCount -gt 1)
    {
        $msg = "Failed to rename website ""${Name}"" because there are ${siteCount} websites that match that name."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $site.Name = $NewName
    Save-CIisConfiguration
}