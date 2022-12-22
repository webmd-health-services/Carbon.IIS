

function Restart-CIisAppPool
{
    <#
    .SYNOPSIS
    Restarts an IIS application pool.

    .DESCRIPTION
    The `Restart-CIisAppPool` restarts an IIS application pool. Pass the names of the application pools to restart to
    the `Name` parameter. You can also pipe application pool objects or application pool names.

    The application pool is stopped then started. If stopping the application pool fails, the function does not attempt
    to start it. If after 30 seconds, the application pool hasn't stopped, the function writes an error, and returns; it
    does not attempt to start the application pool. Use the `Timeout` parameter to control how long to wait for the
    application pool to stop. When the application pool hasn't stopped, and the `Force` parameter is true, the function
    attempts to kill all of the application pool's worker processes, again waiting for `Timeout` interval for the
    processes to exit. If the function is unable to kill the worker processes, the function will write an error.

    .EXAMPLE
    Restart-CIisAppPool -Name 'Default App Pool'

    Demonstrates how to restart an application pool by passing its name to the `Name` parameter.

    .EXAMPLE
    Restart-CIisAppPool -Name 'Default App Pool', 'Non-default App Pool'

    Demonstrates how to restart multiple application pools by passing their names to the `Name` parameter.

    .EXAMPLE
    Get-CIisAppPool | Restart-CIisAppPool

    Demonstrates how to restart an application pool by piping it to `Restart-CIisAppPool`.

    .EXAMPLE
    'Default App Pool', 'Non-default App Pool' | Restart-CIisAppPool

    Demonstrates how to restart one or more application pools by piping their names to `Restart-CIisAppPool`.

    .EXAMPLE
    Restart-CIisAppPool -Name 'Default App Pool' -Timeout '00:00:10'

    Demonstrates how to change the amount of time `Restart-CIisAppPool` waits for the application pool to stop. In this
    example, it will wait 10 seconds.

    .EXAMPLE
    Restart-CIisAppPool -Name 'Default App Pool' -Force

    Demonstrates how to stop an application pool that won't stop by using the `Force` (switch). After waiting for the
    application pool to stop, if it is still running and the `Force` (switch) is used, `Restart-CIisAppPool` will
    try to kill the application pool's worker processes.
    #>
    [CmdletBinding()]
    param(
        # One or more names of the application pools to restart. You can also pipe one or more names to the function or
        # pipe one or more application pool objects.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String[]] $Name,

        # The amount of time `Restart-CIisAppPool` waits for an application pool to stop before giving up and writing
        # an error. The default is 30 seconds.
        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 30),

        # If set, and an application pool fails to stop on its own, `Restart-CIisAppPool` will attempt to kill the
        # application pool worker processes.
        [switch] $Force
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $stopErrors = @()

        Stop-CIisAppPool -Name $Name -Timeout $Timeout -Force:$Force -ErrorVariable 'stopErrors'

        if ($stopErrors)
        {
            return
        }

        Start-CIisAppPool -Name $Name -Timeout $Timeout
    }
}
