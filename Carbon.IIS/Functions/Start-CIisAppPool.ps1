
function Start-CIisAppPool
{
    <#
    .SYNOPSIS
    Starts IIS application pools.

    .DESCRIPTION
    The `Start-CIisAppPool` starts IIS application pools. Pass the names of the application pools to the `Name`
    parameter, or pipe application pool objects or application pool names to `Start-CIisAppPool`. The function then
    starts the application pool and waits 30 seconds for the application pool to report that it has started. You can
    change the amount of time it waits with the `Timeout` parameter. If the application pool doesn't start before the
    timeout expires, the function writes an error.

    .EXAMPLE
    Start-CIisAppPool -Name 'Default App Pool'

    Demonstrates how to start an application pool by passing its name to the `Name` parameter.

    .EXAMPLE
    Start-CIisAppPool -Name 'Default App Pool', 'Non-default App Pool'

    Demonstrates how to start multiple application pools by passing their names to the `Name` parameter.

    .EXAMPLE
    Get-CIisAppPool | Start-CIisAppPool

    Demonstrates how to start an application pool by piping it to `Start-CIisAppPool`.

    .EXAMPLE
    'Default App Pool', 'Non-default App Pool' | Start-CIisAppPool

    Demonstrates how to start one or more application pools by piping their names to `Start-CIisAppPool`.

    .EXAMPLE
    Start-CIisAppPool -Name 'Default App Pool' -Timeout '00:00:10'

    Demonstrates how to change the amount of time `Start-CIisAppPool` waits for the application pool to start. In this
    example, it will wait 10 seconds.
    #>
    param(
        # One or more names of the application pools to start. You can also pipe one or more names to the function or
        # pipe one or more application pool objects.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String[]] $Name,

        # The amount of time `Start-CIisAppPool` waits for an application pool to start before giving up and writing
        # an error. The default is 30 seconds. This doesn't mean the application pool actually has running worker
        # processes, just that it is reporting that is is started and available.
        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 30)
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
            if ($appPool.State -eq [ObjectState]::Started)
            {
                continue
            }

            Write-Information "Starting IIS application pool ""$($appPool.Name)""."
            $state = $null
            $timer.Restart()
            $lastError = $null
            while ($null -eq $state -and $timer.Elapsed -lt $Timeout)
            {
                try
                {
                    $state = $appPool.Start()
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
                $msg = "Starting IIS application pool ""$($appPool.Name)"" threw an exception: $($lastError)."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            if ($state -eq [ObjectState]::Started)
            {
                continue
            }

            while ($true)
            {
                if ($timer.Elapsed -gt $Timeout)
                {
                    $msg = "IIS application pool ""$($appPool.Name)"" failed to start in less than $($Timeout)."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    break
                }

                $appPool = Get-CIisAppPool -Name $appPool.Name
                if ($appPool.State -eq [ObjectState]::Started)
                {
                    break
                }

                Start-Sleep -Milliseconds 100
            }
        }
    }
}
