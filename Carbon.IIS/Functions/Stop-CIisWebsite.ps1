
function Stop-CIisWebsite
{
    <#
    .SYNOPSIS
    Stops an IIS website.

    .DESCRIPTION
    The `Stop-CIisWebsite` stops an IIS website. Pass the names of the websites to the `Name` parameter, or pipe website
    objects or website names to `Stop-CIisWebsite`. The function will stop the website, then waits 30 seconds for it to
    stop (you can control this wait period with the `Timeout` parameter). If the website hasn't stopped, the function
    writes an error, and returns.

    .EXAMPLE
    Stop-CIisWebsite -Name 'Default Website'

    Demonstrates how to stop a website by passing its name to the `Name` parameter.

    .EXAMPLE
    Stop-CIisWebsite -Name 'Default Website', 'Non-default Website'

    Demonstrates how to stop multiple websites by passing their names to the `Name` parameter.

    .EXAMPLE
    Get-CIisWebsite | Stop-CIisWebsite

    Demonstrates how to stop a website by piping it to `Stop-CIisWebsite`.

    .EXAMPLE
    'Default Website', 'Non-default Website' | Stop-CIisWebsite

    Demonstrates how to stop one or more websites by piping their names to `Stop-CIisWebsite`.

    .EXAMPLE
    Stop-CIisWebsite -Name 'Default Website' -Timeout '00:00:10'

    Demonstrates how to change the amount of time `Stop-CIisWebsite` waits for the website to stop. In this
    example, it will wait 10 seconds.
    #>
    [CmdletBinding()]
    param(
        # One or more names of the websites to stop. You can also pipe one or more names to the function or
        # pipe one or more website objects.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String[]] $Name,

        # The amount of time `Stop-CIisWebsite` waits for a website to stop before giving up and writing
        # an error. The default is 30 seconds.
        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 30)
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $websites = $Name | ForEach-Object { Get-CIisWebsite -Name $_ }
        if (-not $websites)
        {
            return
        }

        $timer = [Diagnostics.Stopwatch]::New()

        foreach ($website in $websites)
        {
            if ($website.State -eq [ObjectState]::Stopped)
            {
                continue
            }

            Write-Information "Stopping IIS website ""$($website.Name)""."
            $state = $null
            $lastError = $null
            $timer.Restart()
            $numErrorsAtStart = $Global:Error.Count
            while ($null -eq $state -and $timer.Elapsed -lt $Timeout)
            {
                try
                {
                    $state = $website.Stop()
                }
                catch
                {
                    $lastError = $_
                    Start-Sleep -Milliseconds 100
                    $website = Get-CIisWebsite -Name $website.Name
                }
            }

            if ($null -eq $state)
            {
                $msg = "Failed to stop IIS website ""$($website.Name)"": $($lastError)"
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }
            else
            {
                # Site stopped successfully, so remove the errors.
                $numErrorsToRemove = $Global:Error.Count - $numErrorsAtStart
                for ($idx = 0; $idx -lt $numErrorsToRemove; ++$idx)
                {
                    $Global:Error.RemoveAt(0)
                }
            }

            if ($state -eq [ObjectState]::Stopped)
            {
                continue
            }

            while ($true)
            {
                $website = Get-CIisWebsite -Name $website.Name
                if ($website.State -eq [ObjectState]::Stopped)
                {
                    break
                }

                if ($timer.Elapsed -gt $Timeout)
                {
                    $msg = "IIS website ""$($website.Name)"" failed to stop in ""$($Timeout)""."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    break
                }

                Start-Sleep -Milliseconds 100
            }
        }
    }
}
