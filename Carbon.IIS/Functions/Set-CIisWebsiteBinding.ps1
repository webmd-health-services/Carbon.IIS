
function Set-CIisWebsiteBinding
{
    <#
    .SYNOPSIS
    Sets configuration on a website's bindings.

    .DESCRIPTION
    The `Set-CIisWebsiteBinding` function configures bindings on a website. Pass the website name to the `SiteName`
    parameter. Pass the SSL flags to set on all the website's HTTPS bindings to the `SslFlag` parameter. The function
    will update each HTTPS binding's SSL flags to match what is passed in. If they already match, the function does
    nothing. When setting the SslFlags setting, the function automatically skips non-HTTPS bindings.

    To only update a specific binding, pass the binding information to the `BindingInformation` parameter. You can also
    pipe binding information and/or actual binding objects.

    .EXAMPLE
    Set-CIisWebsiteBinding -SiteName 'example.com' -SslFlag ([Microsoft.Web.Administration.SslFlags]:Sni)

    Demonstrates how to require SNI (i.e. server name indication) on all of the example.com website's HTTPS bindings.

    .EXAMPLE
    Set-CIisWebsiteBinding -SiteName 'example.com' -BindingInformation '*:443:example.com' -SslFlag ([Microsoft.Web.Administration.SslFlags]:Sni)

    Demonstrates how to only update a specific binding by passing its binding information string to the
    `BindingInformation` parameter.

    .EXAMPLE
    Get-CIisWebsite -Name 'example.com' | Select-Object -ExpandProperty 'Bindings' | Where-Object 'Protocol' -EQ 'https' | Where-Object 'Host' -NE '' | Set-CIisWebsiteBinding -SiteName 'example.com' -SslFlag Sni

    Demonstrates that you can pipe binding objects into `Set-CIisWebsiteBinding`. In this example, only HTTPS and
    hostname bindings will get updated to have the `Sni` SSL flag.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website whose bindings to update.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The specific binding to set. Binding information must be in the IP-ADDRESS:PORT:HOSTNAME format. Can also be
        # piped in as strings or binding objects.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $BindingInformation,

        # The SSL flags for each of the website's HTTPS bindings. If a value for this parameter is omitted, the function
        # does nothing (i.e. existing SSL flags are not changed).
        [SslFlags] $SslFlag
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $bindings = Get-CIisWebsite -Name $SiteName | Select-Object -ExpandProperty 'Bindings'
        $updated = $false
    }

    process
    {
        foreach ($binding in $bindings)
        {
            if ($BindingInformation -and $binding.BindingInformation -ne $BindingInformation)
            {
                continue
            }

            if ($binding.Protocol -ne 'https')
            {
                continue
            }

            if (-not $PSBoundParameters.ContainsKey('SslFlag'))
            {
                continue
            }

            if ($binding.SslFlags -eq $SslFlag)
            {
                continue
            }

            if ($SslFlag.HasFlag([SslFlags]::Sni))
            {
                if (-not $binding.Host)
                {
                    $msg = "Unable to set SSL flags for binding ""$($binding.BindingInformation)"" because the " +
                           """Sni"" flag is set but the binding doesn't have a hostname."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    continue
                }
            }

            $msg = "${SiteName}  $($binding.Protocol)/$($binding.BindingInformation)  SslFlags  $($binding.SslFlags) -> " +
                "${SslFlag}"
            Write-Information $msg
            $binding.SslFlags = $SslFlag
            $updated = $true
        }
    }

    end
    {
        if ($updated)
        {
            Save-CIisConfiguration
        }
    }
}
