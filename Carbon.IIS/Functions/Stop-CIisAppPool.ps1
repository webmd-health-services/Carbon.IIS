
function Stop-CIisAppPool
{
    <#
    .SYNOPSIS
    Stops an IIS application pool.

    .DESCRIPTION
    The `Stop-CIisAppPool` stops an IIS application pool. Pass the names of the application pools to the `Name`
    parameter, or pipe application pool objects or application pool names to `Stop-CIisAppPool`. The function will
    stop the application pool, then waits 30 seconds for it to stop (you can control this wait period with the
    `Timeout` parameter). If the application pool hasn't stopped, the function writes an error, and returns.

    You can use the `Force` (switch) to indicate to `Stop-CIisAppPool` that it should attempt to kill/stop any of the
    application pool's worker processes if the application pool doesn't stop before the timeout completes. If killing
    the worker processes fails, the function writes an error.

    This function disposes the current server manager object that Carbon.IIS uses internally. Make sure you have no
    pending, unsaved changes when calling `Stop-CIisAppPool`.

    .EXAMPLE
    Stop-CIisAppPool -Name 'Default App Pool'

    Demonstrates how to stop an application pool by passing its name to the `Name` parameter.

    .EXAMPLE
    Stop-CIisAppPool -Name 'Default App Pool', 'Non-default App Pool'

    Demonstrates how to stop multiple application pools by passing their names to the `Name` parameter.

    .EXAMPLE
    Get-CIisAppPool | Stop-CIisAppPool

    Demonstrates how to stop an application pool by piping it to `Stop-CIisAppPool`.

    .EXAMPLE
    'Default App Pool', 'Non-default App Pool' | Stop-CIisAppPool

    Demonstrates how to stop one or more application pools by piping their names to `Stop-CIisAppPool`.

    .EXAMPLE
    Stop-CIisAppPool -Name 'Default App Pool' -Timeout '00:00:10'

    Demonstrates how to change the amount of time `Stop-CIisAppPool` waits for the application pool to stop. In this
    example, it will wait 10 seconds.

    .EXAMPLE
    Stop-CIisAppPool -Name 'Default App Pool' -Force

    Demonstrates how to stop an application pool that won't stop by using the `Force` (switch). After waiting for the
    application pool to stop, if it is still running and the `Force` (switch) is used, `Stop-CIisAppPool` will
    try to kill the application pool's worker processes.
    #>
    [CmdletBinding()]
    param(
        # One or more names of the application pools to stop. You can also pipe one or more names to the function or
        # pipe one or more application pool objects.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String[]] $Name,

        # The amount of time `Stop-CIisAppPool` waits for an application pool to stop before giving up and writing
        # an error. The default is 30 seconds.
        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 30),

        # If set, and an application pool fails to stop on its own, `Stop-CIisAppPool` will attempt to kill the
        # application pool worker processes.
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $appPools = $Name | ForEach-Object { Get-CIisAppPool -Name $_ }
        if (-not $appPools)
        {
            return
        }

        $timer = [Diagnostics.Stopwatch]::New()

        foreach ($appPool in $appPools)
        {
            if ($appPool.State -eq [ObjectState]::Stopped)
            {
                continue
            }

            Write-Information "Stopping IIS application pool ""$($appPool.Name)""."
            $state = $null
            $lastError = $null
            $timer.Restart()
            while ($null -eq $state -and $timer.Elapsed -lt $Timeout)
            {
                try
                {
                    $state = $appPool.Stop()
                }
                catch
                {
                    $lastError = $_
                    Start-Sleep -Milliseconds 100
                    $appPool = Get-CIisAppPool -Name $appPool.Name
                }
            }

            if ($null -eq $state)
            {
                $msg = "Failed to stop IIS application pool ""$($appPool.Name)"": $($lastError)"
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            if ($state -eq [ObjectState]::Stopped)
            {
                continue
            }

            while ($true)
            {
                $appPool = Get-CIisAppPool -Name $appPool.Name
                if ($appPool.State -eq [ObjectState]::Stopped)
                {
                    break
                }

                if ($timer.Elapsed -gt $Timeout)
                {
                    if ($Force)
                    {
                        $appPool = Get-CIisAppPool -Name $appPool.Name

                        foreach ($wp in $appPool.WorkerProcesses)
                        {
                            $msg = "IIS application pool ""$($appPool.Name)"" failed to stop in less than " +
                                   "$($Timeout): forcefully stopping worker process $($wp.ProcessId)."
                            Write-Warning $msg
                            Stop-Process -id $wp.ProcessId -Force -ErrorAction Ignore

                            $timer.Restart()
                            while ($true)
                            {
                                if (-not (Get-Process -Id $wp.ProcessId -ErrorAction Ignore))
                                {
                                    break
                                }

                                if ($timer.Elapsed -gt $Timeout)
                                {
                                    $msg = "IIS application pool ""$($appPool.Name)"" failed to stop in less than " +
                                           "$($Timeout) and its worker process $($wp.ProcessId) also failed to stop " +
                                           "in less than $($Timeout)."
                                    Write-Error -Message $msg
                                    break
                                }

                                Start-Sleep -Milliseconds 100
                            }
                        }
                        break
                    }

                    $msg = "IIS application pool ""$($appPool.Name)"" failed to stop in ""$($Timeout)""."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    break
                }

                Start-Sleep -Milliseconds 100
            }
        }
    }
}
