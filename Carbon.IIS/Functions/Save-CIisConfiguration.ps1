
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
        [String] $Target,

        [String] $Action,

        [String] $Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $serverMgr = Get-CIisServerManager

    $msgPrefix = "ServerManager  #$('{0,-10}' -f $serverMgr.GetHashCode())  "

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

        Write-Debug "$($msgPrefix)Dispose()"
        $serverMgr.Dispose()
        return
    }

    $applicationHostPath =
        Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config'
    $lastWriteTimeUtc = Get-Item -Path $applicationHostPath | Select-Object -ExpandProperty 'LastWriteTimeUtc'

    $serverMgr = Get-CIisServerManager
    try
    {
        if( $Message )
        {
            Write-Information $Message
        }
        Write-Debug "$($msgPrefix)CommitChanges()"
        $serverMgr.CommitChanges()

        $tryFor = [TimeSpan]::New(0, 0, 1)
        $startedWaitingAt = [Diagnostics.Stopwatch]::StartNew()
        do
        {
            $appHostInfo = Get-Item -Path $applicationHostPath -ErrorAction Ignore
            if( $appHostInfo -and $lastWriteTimeUtc -lt $appHostInfo.LastWriteTimeUtc )
            {
                Write-Debug "    $($startedWaitingAt.Elapsed.TotalSeconds.ToString('0.000'))s  Changes committed."
                return
            }
            Write-Debug "  ! $($startedWaitingAt.Elapsed.TotalSeconds.ToString('0.000'))s  Waiting."
            Start-Sleep -Milliseconds 100
        }
        while( $startedWaitingAt.Elapsed -lt $tryFor )
        $msg = "Your IIS changes haven't been saved after waiting for $([int]$tryFor.TotalSeconds) seconds. You may need " +
               "to wait a little longer or restart IIS."
        Write-Warning $msg
    }
    catch
    {
        Write-Error $_ -ErrorAction $ErrorActionPreference
        return
    }
    finally
    {
        Write-Debug "$($msgPrefix)Dispose()"
        $serverMgr.Dispose()
    }

}