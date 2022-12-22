
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
        # Disposes the current server manager, creates a new one, and returns it.
        [Parameter(Mandatory, ParameterSetName='Reset')]
        [switch] $Reset,

        # Saves changes to the current server manager, disposes it, creates a new server manager object, and returns
        # that new server manager objet.
        [Parameter(Mandatory, ParameterSetName='Commit')]
        [switch] $Commit,

        [Parameter(ParameterSetName='Commit')]
        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 10)
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function New-MessagePrefix
    {
        return "ServerManager  #$('{0,-10}  ' -f $script:serverMgr.GetHashCode())"
    }

    $msgPrefix = New-MessagePrefix

    if ($Commit)
    {
        $applicationHostPath =
            Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config'
        $lastWriteTimeUtc = Get-Item -Path $applicationHostPath | Select-Object -ExpandProperty 'LastWriteTimeUtc'

        try
        {
            Write-Debug "$($msgPrefix)CommitChanges()"
            $serverMgr.CommitChanges()

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
            while ($startedWaitingAt.Elapsed -lt $Timeout)

            $msg = "Your IIS changes haven't been saved after waiting for $($Timeout) seconds. You may need to wait " +
                   'a little longer or restart IIS.'
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

    if ($Reset)
    {
        Write-Debug "$($msgPrefix)Dispose()"
        $script:serverMgr.Dispose()
    }

    # It's been disposed.
    if( -not $script:serverMgr.ApplicationPoolDefaults )
    {
        $script:serverMgr = [Microsoft.Web.Administration.ServerManager]::New()
        $msgPrefix = New-MessagePrefix
        Write-Debug "$($msgPrefix)New()"
    }

    Write-Debug "$($msgPrefix)"
    return $script:serverMgr
}
