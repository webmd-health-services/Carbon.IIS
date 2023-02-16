
function Enable-CIisHttps
{
    <#
    .SYNOPSIS
    Turns on and configures HTTPS for a website or part of a website.

    .DESCRIPTION
    This function enables HTTPS and optionally the site/directory to:

     * Require HTTPS (the `RequireHttps` switch)
     * Ignore/accept/require client certificates (the `AcceptClientCertificates` and `RequireClientCertificates` switches).
     * Requiring 128-bit HTTPS (the `Require128BitHttps` switch).

    By default, this function will enable HTTPS, make HTTPS connections optional, ignores client certificates, and not
    require 128-bit HTTPS.

    Changing any HTTPS settings will do you no good if the website doesn't have an HTTPS binding or doesn't have an
    HTTPS certificate.  The configuration will most likely succeed, but won't work in a browser.  So sad.

    Beginning with IIS 7.5, the `Require128BitHttps` parameter won't actually change the behavior of a website since
    [there are no longer 128-bit crypto providers](https://forums.iis.net/p/1163908/1947203.aspx) in versions of Windows
    running IIS 7.5.

    .LINK
    http://support.microsoft.com/?id=907274

    .LINK
    Set-CIisWebsiteHttpsCertificate

    .EXAMPLE
    Enable-CIisHttps -LocationPath 'Peanuts'

    Enables HTTPS on the `Peanuts` website's, making makes HTTPS connections optional, ignoring client certificates, and
    making 128-bit HTTPS optional.

    .EXAMPLE
    Enable-CIisHttps -LocationPath 'Peanuts/Snoopy/DogHouse' -RequireHttps

    Configures the `/Snoopy/DogHouse` directory in the `Peanuts` site to require HTTPS.  It also turns off any client
    certificate settings and makes 128-bit HTTPS optional.

    .EXAMPLE
    Enable-CIisHttps -LocationPath 'Peanuts' -AcceptClientCertificates

    Enables HTTPS on the `Peanuts` website and configures it to accept client certificates, makes HTTPS optional, and
    makes 128-bit HTTPS optional.

    .EXAMPLE
    Enable-CIisHttps -LocationPath 'Peanuts' -RequireHttps -RequireClientCertificates

    Enables HTTPS on the `Peanuts` website and configures it to require HTTPS and client certificates.  You can't require
    client certificates without also requiring HTTPS.

    .EXAMPLE
    Enable-CIisHttps -LocationPath 'Peanuts' -Require128BitHttps

    Enables HTTPS on the `Peanuts` website and require 128-bit HTTPS.  Also, makes HTTPS connections optional and
    ignores client certificates.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='IgnoreClientCertificates')]
    param(
        # The website whose HTTPS flags should be modifed.
        [Parameter(Mandatory, Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

        # Should HTTPS be required?
        [Parameter(ParameterSetName='IgnoreClientCertificates')]
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [Parameter(Mandatory, ParameterSetName='RequireClientCertificates')]
        [switch] $RequireHttps,

        # Requires 128-bit HTTPS. Only changes IIS behavior in IIS 7.0.
        [switch] $Require128BitHttps,

        # Should client certificates be accepted?
        [Parameter(Mandatory, ParameterSetName='AcceptClientCertificates')]
        [switch] $AcceptClientCertificates,

        # Should client certificates be required?  Also requires HTTPS ('RequireHttps` switch).
        [Parameter(Mandatory, ParameterSetName='RequireClientCertificates')]
        [switch] $RequireClientCertificates
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $httpsFlags = [CIisHttpsFlags]::None
    if( $RequireHttps -or $RequireClientCertificates )
    {
        $httpsFlags = $httpsFlags -bor [CIisHttpsFlags]::Ssl
    }

    if( $AcceptClientCertificates -or $RequireClientCertificates )
    {
        $httpsFlags = $httpsFlags -bor [CIisHttpsFlags]::SslNegotiateCert
    }

    if( $RequireClientCertificates )
    {
        $httpsFlags = $httpsFlags -bor [CIisHttpsFlags]::SslRequireCert
    }

    if( $Require128BitHttps )
    {
        $httpsFlags = $httpsFlags -bor [CIisHttpsFlags]::Ssl128
    }

    Set-CIisConfigurationAttribute -LocationPath (Join-CIisPath $LocationPath,$VirtualPath) `
                                   -SectionPath 'system.webServer/security/access' `
                                   -Name 'sslFlags' `
                                   -Value $httpsFlags
}

