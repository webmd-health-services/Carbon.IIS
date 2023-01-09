
function Get-CIisServerManager
{
    <#
    .SYNOPSIS
    Returns the current instance of the `Microsoft.Web.Administration.ServerManager` class.

    .DESCRIPTION
    The `Get-CIisServerManager` function returns the current instance of `Microsoft.Web.Administration.ServerManager`
    that the Carbon.IIS module is using. After committing changes, the current server manager is destroyed (i.e.
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
    [CmdletBinding(DefaultParameterSetName='Get')]
    param(
        # Saves changes to the current server manager, disposes it, creates a new server manager object, and returns
        # that new server manager objet.
        [Parameter(Mandatory, ParameterSetName='Commit')]
        [switch] $Commit,

        # Resets and creates a new server manager. Any unsaved changes are lost.
        [Parameter(Mandatory, ParameterSetName='Reset')]
        [switch] $Reset,

        [Parameter(ParameterSetName='Commit')]
        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 10)
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function New-MessagePrefix
    {
        return "$(([DateTime]::UtcNow.ToString('O')))  ServerManager  #$('{0,-10}  ' -f $script:serverMgr.GetHashCode())"
    }

    $lastWriteTimeUtc = Get-Item -Path $script:applicationHostPath | Select-Object -ExpandProperty 'LastWriteTimeUtc'

    $msgPrefix = New-MessagePrefix

    if ($lastWriteTimeUtc -gt $script:serverMgrCreatedAt)
    {
        $msg = "$($msgPrefix)Stale  $($lastWriteTimeUtc.ToString('O')) > $($script:serverMgrCreatedAt.ToString('O'))"
        Write-Debug $msg
        $Reset = $true
    }

    if ($Commit)
    {
        try
        {
            Write-Debug "$($msgPrefix)CommitChanges()"
            $serverMgr.CommitChanges()

            $startedWaitingAt = [Diagnostics.Stopwatch]::StartNew()
            do
            {
                if ($startedWaitingAt.Elapsed -gt $Timeout)
                {
                    $msg = "Your IIS changes haven't been saved after waiting for $($Timeout) seconds. You may need " +
                           'to wait a little longer or restart IIS.'
                    Write-Warning $msg
                    break
                }

                $appHostInfo = Get-Item -Path $script:applicationHostPath -ErrorAction Ignore
                if( $appHostInfo -and $lastWriteTimeUtc -lt $appHostInfo.LastWriteTimeUtc )
                {
                    Write-Debug "    $($startedWaitingAt.Elapsed.TotalSeconds.ToString('0.000'))s  Changes committed."
                    $Reset = $true
                    break
                }
                Write-Debug "  ! $($startedWaitingAt.Elapsed.TotalSeconds.ToString('0.000'))s  Waiting."
                Start-Sleep -Milliseconds 100
            }
            while ($true)
        }
        catch
        {
            Write-Error $_ -ErrorAction $ErrorActionPreference
            return
        }
    }

    if ($Reset)
    {
        Write-Debug "$($msgPrefix)Dispose()"
        $script:serverMgr.Dispose()
    }

    # It's been disposed.
    if( -not $script:serverMgr.ApplicationPoolDefaults )
    {
        $script:serverMgr = [Microsoft.Web.Administration.ServerManager]::New()
        $script:serverMgrCreatedAt = [DateTime]::UtcNow
        $msgPrefix = New-MessagePrefix
        Write-Debug "$($msgPrefix)New()"
    }

    Write-Debug "$($msgPrefix)"
    return $script:serverMgr
}
