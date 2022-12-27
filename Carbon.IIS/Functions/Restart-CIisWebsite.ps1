

function Restart-CIisWebsite
{
    <#
    .SYNOPSIS
    Restarts an IIS website.

    .DESCRIPTION
    The `Restart-CIisWebsite` restarts an IIS website. Pass the names of the websites to restart to the `Name`
    parameter. You can also pipe website objects or website names.

    The website is stopped then started. If stopping the website fails, the function does not attempt to start it. If
    after 30 seconds, the website hasn't stopped, the function writes an error, and returns; it does not attempt to
    start the website. Use the `Timeout` parameter to control how long to wait for the website to stop. The function
    writes an error if the website doesn't stop or start.

    .EXAMPLE
    Restart-CIisWebsite -Name 'Defaul Website'

    Demonstrates how to restart an website by passing its name to the `Name` parameter.

    .EXAMPLE
    Restart-CIisWebsite -Name 'Defaul Website', 'Non-default Website'

    Demonstrates how to restart multiple websites by passing their names to the `Name` parameter.

    .EXAMPLE
    Get-CIisWebsite | Restart-CIisWebsite

    Demonstrates how to restart an website by piping it to `Restart-CIisWebsite`.

    .EXAMPLE
    'Defaul Website', 'Non-default Website' | Restart-CIisWebsite

    Demonstrates how to restart one or more websites by piping their names to `Restart-CIisWebsite`.

    .EXAMPLE
    Restart-CIisWebsite -Name 'Defaul Website' -Timeout '00:00:10'

    Demonstrates how to change the amount of time `Restart-CIisWebsite` waits for the website to stop. In this
    example, it will wait 10 seconds.
    #>
    [CmdletBinding()]
    param(
        # One or more names of the websites to restart. You can also pipe one or more names to the function or
        # pipe one or more website objects.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String[]] $Name,

        # The amount of time `Restart-CIisWebsite` waits for an website to stop before giving up and writing
        # an error. The default is 30 seconds.
        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 30)
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $stopErrors = @()

        Stop-CIisWebsite -Name $Name -Timeout $Timeout -ErrorVariable 'stopErrors'

        if ($stopErrors)
        {
            return
        }

        Start-CIisWebsite -Name $Name -Timeout $Timeout
    }
}
