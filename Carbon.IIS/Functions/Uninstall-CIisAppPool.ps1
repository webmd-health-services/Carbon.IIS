
function Uninstall-CIisAppPool
{
    <#
    .SYNOPSIS
    Removes an IIS application pool.

    .DESCRIPTION
    If the app pool doesn't exist, nothing happens.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Uninstall-CIisAppPool -Name Batcave

    Removes/uninstalls the `Batcave` app pool.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the app pool to remove.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $Name -ErrorAction Ignore
    if( -not $appPool )
    {
        return
    }

    $target = "IIS Application Pool $($Name)"
    if ($PSCmdlet.ShouldProcess($target, 'Stop'))
    {
        # Stop the app pool first, otherwise it can sometimes still be running after this function returns.
        Stop-CIisAppPool -Name $Name
    }

    $appPool = Get-CIisAppPool -Name $Name
    if ($PSCmdlet.ShouldProcess($target, 'Remove'))
    {
        Write-Information -Message "Removing IIS application pool ""$($Name)""."
        $appPool.Delete()
    }
    Save-CIisConfiguration
}

