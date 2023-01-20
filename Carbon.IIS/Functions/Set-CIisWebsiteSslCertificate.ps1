
function Set-CIisWebsiteSslCertificate
{
    <#
    .SYNOPSIS
    Sets a website's HTTPS certificate.

    .DESCRIPTION
    The `Set-CiisWebsiteSslCertificate` sets the HTTPS certificate for all of a website's HTTPS bindings. Pass the
    website name to the SiteName parameter, the certificate thumbprint to the `Thumbprint` parameter (the certificate
    should be in the LocalMachine's My store), and the website's application ID (a GUID that uniquely identifies the
    website) to the `ApplicationID` parameter. The function gets all the unique IP address/port HTTPS bindings and
    creates a binding for that address/port to the given certificate. Any  HTTPS bindings on that address/port that
    don't use this thumbprint and application ID are removed.

    Make sure you call this method *after* you create a website's bindings.

    .EXAMPLE
    Set-CIisWebsiteSslCertificate -SiteName Peanuts -Thumbprint 'a909502dd82ae41433e6f83886b00d4277a32a7b' -ApplicationID $PeanutsAppID

    Binds the certificate whose thumbprint is `a909502dd82ae41433e6f83886b00d4277a32a7b` to the `Peanuts` website.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website whose SSL certificate is being set.
        [Parameter(Mandatory)]
        [string] $SiteName,

        # The thumbprint of the SSL certificate to use.
        [Parameter(Mandatory)]
        [string] $Thumbprint,

        # A GUID that uniquely identifies this website.  Create your own.
        [Parameter(Mandatory)]
        [Guid] $ApplicationID
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $SiteName
    if( -not $site )
    {
        return
    }

    foreach ($binding in ($site.Bindings | Where-Object 'Protocol' -EQ 'https'))
    {
        $endpoint = $binding.Endpoint

        $portArg = @{
            Port = $endpoint.Port;
        }
        if ($endpoint.Port -eq '*')
        {
            $portArg['Port'] = 443
        }

        Set-CSslCertificateBinding -IPAddress $binding.Endpoint.Address `
                                    @portArg `
                                    -Thumbprint $Thumbprint `
                                    -ApplicationID $ApplicationID
    }
}

