
function Start-CIisWebsite
{
    <#
    .SYNOPSIS
    Starts IIS websites.

    .DESCRIPTION
    The `Start-CIisWebsite` starts IIS websites. Pass the names of the websites to the `Name` parameter, or pipe website
    objects or website names to `Start-CIisWebsite`. The function then starts the website and waits 30 seconds for the
    website to report that it has started. You can change the amount of time it waits with the `Timeout` parameter. If
    the website doesn't start before the timeout expires, the function writes an error.

    .EXAMPLE
    Start-CIisWebsite -Name 'Default Website'

    Demonstrates how to start a website by passing its name to the `Name` parameter.

    .EXAMPLE
    Start-CIisWebsite -Name 'Default Website', 'Non-default Website'

    Demonstrates how to start multiple websites by passing their names to the `Name` parameter.

    .EXAMPLE
    Get-CIisWebsite | Start-CIisWebsite

    Demonstrates how to start a website by piping it to `Start-CIisWebsite`.

    .EXAMPLE
    'Default Website', 'Non-default Website' | Start-CIisWebsite

    Demonstrates how to start one or more websites by piping their names to `Start-CIisWebsite`.

    .EXAMPLE
    Start-CIisWebsite -Name 'Default Website' -Timeout '00:00:10'

    Demonstrates how to change the amount of time `Start-CIisWebsite` waits for the website to start. In this
    example, it will wait 10 seconds.
    #>
    param(
        # One or more names of the websites to start. You can also pipe one or more names to the function or
        # pipe one or more website objects.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String[]] $Name,

        # The amount of time `Start-CIisWebsite` waits for a website to start before giving up and writing
        # an error. The default is 30 seconds. This doesn't mean the website actually has running worker
        # processes, just that it is reporting that is is started and available.
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
            if ($website.State -eq [ObjectState]::Started)
            {
                continue
            }

            $siteAppPoolName =
                $website.Applications |
                Where-Object 'Path' -eq '/' |
                Select-Object -ExpandProperty 'ApplicationPoolName'
            if (-not (Test-CIisAppPool -Name $siteAppPoolName))
            {
                $msg = "Unable to start website ""$($website.Name)"" because its application pool, " +
                       """$($siteAppPoolName)"", does not exist."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            Write-Information "Starting IIS website ""$($website.Name)""."
            $state = $null
            $lastError = $null
            $timer.Restart()
            $numErrorsAtStart = $Global:Error.Count
            while ($null -eq $state -and $timer.Elapsed -lt $Timeout)
            {
                try
                {
                    $state = $website.Start()
                }
                catch
                {
                    if ($script:skipCommit)
                    {
                        return
                    }

                    $lastError = $_
                    Start-Sleep -Milliseconds 100
                    $website = Get-CIisWebsite -Name $website.Name
                }
            }

            if ($null -eq $state)
            {
                $msg = "Starting IIS website ""$($website.Name)"" threw an exception: $($lastError)."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }
            else
            {
                # Site started successfully, so remove the errors.
                $numErrorsToRemove = $Global:Error.Count - $numErrorsAtStart
                for ($idx = 0; $idx -lt $numErrorsToRemove; ++$idx)
                {
                    $Global:Error.RemoveAt(0)
                }
            }

            if ($state -eq [ObjectState]::Started)
            {
                continue
            }

            while ($true)
            {
                $website = Get-CIisWebsite -Name $website.Name
                if ($website.State -eq [ObjectState]::Started)
                {
                    break
                }

                if ($timer.Elapsed -gt $Timeout)
                {
                    $msg = "IIS website ""$($website.Name)"" failed to start in less than $($Timeout)."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    break
                }

                Start-Sleep -Milliseconds 100
            }
        }
    }
}
