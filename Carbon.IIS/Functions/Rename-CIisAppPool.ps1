
function Rename-CIisAppPool
{
    <#
    .SYNOPSIS
    Renames an IIS application pool.

    .DESCRIPTION
    The `Rename-CIisAppPool` function renames an IIS application pool. Pass the name of the application pool to the
    `Name` parameter. Wildcards are permitted if the pattern only matches one application pool. Pass the new name of
    the application pool to the `NewName` parameter.

    If the application pool does not exist, the function writes an error and does nothing.

    If the application pool is assigned to any websites or applications, the rename will fail with an error message. IIS
    doesn't support renaming application pools that are assigned to any website or application.

    .EXAMPLE
    Rename-CIisAppPool -Name 'OldName' -NewName 'NewName'

    Demonstrates how to rename an IIS application with name "OldName" to "NewName".
    #>
    [CmdletBinding()]
    param(
        # The name of the appliciton pool to rename.
        [Parameter(Mandatory)]
        [String] $Name,

        # The website's new name.
        [Parameter(Mandatory)]
        [String] $NewName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $Name

    if (-not $appPool)
    {
        return
    }

    $appPoolCount = ($appPool | Measure-Object).Count
    if ($appPoolCount -gt 1)
    {
        $msg = "Failed to rename application pool ""${Name}"" because there are ${appPoolCount} application pools " +
               'that match that name.'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $appCount =
        Get-CIisApplication |
        Where-Object 'ApplicationPoolName' -EQ $Name |
        Measure-Object |
        Select-Object -ExpandProperty 'Count'
    if ($appCount -gt 0)
    {
        $suffix = ''
        if ($appCount -gt 1)
        {
            $suffix = 's'
        }
        $msg = "Failed to rename application pool ""${Name}"" because it is assigned to ${appCount} " +
               "application${suffix}."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $appPool.Name = $NewName
    Save-CIisConfiguration
}