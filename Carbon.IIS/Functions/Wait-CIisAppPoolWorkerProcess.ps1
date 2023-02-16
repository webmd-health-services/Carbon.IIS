
function Wait-CIisAppPoolWorkerProcess
{
    <#
    .SYNOPSIS
    Waits for an IIS application pool to have running worker processes.

    .DESCRIPTION
    The `Wait-CIisAppPoolWorkerProcess` function waits for an IIS application pool to have running worker processes.
    Pass the name of the application pool to the `AppPoolName` parameter. By default, the function waits 30 seconds for
    there to be at least one running worker process. You can change the timeout by passing a `[TimeSpan]` object to the
    `Timeout` parameter.

    Some IIS application pools don't auto-start: IIS waits to create a worker process until a website under the
    application pool has received a request.

    In order to get an accurate record of the application pool's worker processes, this function creates a new
    internal server manager object for every check. If you have pending changes made by other Carbon.IIS functions,
    call `Save-CIisConfiguration` before calling `Wait-CIisAppPoolWorkerProcess`.

    .EXAMPLE
    Wait-CIisAppPoolWorkerProcess -AppPoolName 'www'

    Demonstrates how to wait for an application pool to have a running worker process by passing the application pool
    name to the `AppPoolName` parameter. In this example, the function will wait for the "www" application pool.

    .EXAMPLE
    Wait-CIisAppPoolWorkerProcess -AppPoolName 'www' -Timeout (New-TimeSpan -Seconds 300)

    Demonstrates how control how long to wait for an application pool to have a running worker process by passing a
    custom `[TimeSpan]` to the `TimeSpan` parameter. In this example, the function will wait 300 seconds (i.e. five
    minutes).
    #>
    [CmdletBinding()]
    param(
        # The name of the application pool
        [Parameter(Mandatory)]
        [String] $AppPoolName,

        # The total amount of time to wait for the application pool to have running worker processes. The default
        # timeout is 30 seconds.
        [TimeSpan] $Timeout = (New-TimeSpan -Seconds 30)
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $AppPoolName
    if (-not $appPool)
    {
        return
    }

    $timer = [Diagnostics.Stopwatch]::StartNew()

    while ($timer.Elapsed -lt $Timeout)
    {
        $mgr = Get-CIisServerManager -Reset
        $appPool = $mgr.ApplicationPools | Where-Object 'Name' -EQ $appPool.Name
        [Object[]] $wps = $appPool.WorkerProcesses
        [Object[]] $pss = $wps | ForEach-Object { Get-Process -Id $_.ProcessId -ErrorAction Ignore }
        if ($wps.Length -eq $pss.Length)
        {
            return
        }

        Start-Sleep -Milliseconds 100
    }

    $msg = "The ""$($appPool.Name)"" IIS application pool's worker processes haven't started after waiting " +
           "$($Timeout)."
    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
}