
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
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [switch] $AcceptClientCertificates,

        # Should client certificates be required?  Also requires HTTPS ('RequireHttps` switch).
        [Parameter(Mandatory, ParameterSetName='RequireClientCertificates')]
        [switch] $RequireClientCertificates
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $HttpsFlags_Https = 8
    $HttpsFlags_NegotiateCert = 32
    $HttpsFlags_RequireCert = 64
    $HttpsFlags_MapCert = 128
    $HttpsFlags_128Bit = 256

    $intFlag = 0
    $flags = @()
    if( $RequireHttps -or $RequireClientCertificates )
    {
        $flags += 'Ssl'
        $intFlag = $intFlag -bor $HttpsFlags_Https
    }

    if( $AcceptClientCertificates -or $RequireClientCertificates )
    {
        $flags += 'SslNegotiateCert'
        $intFlag = $intFlag -bor $HttpsFlags_NegotiateCert
    }

    if( $RequireClientCertificates )
    {
        $flags += 'SslRequireCert'
        $intFlag = $intFlag -bor $HttpsFlags_RequireCert
    }

    if( $Require128BitHttps )
    {
        $flags += 'Ssl128'
        $intFlag = $intFlag -bor $HttpsFlags_128Bit
    }

    $sectionPath = 'system.webServer/security/access'
    $section =
        Get-CIisConfigurationSection -LocationPath $LocationPath -VirtualPath $VirtualPath -SectionPath $sectionPath
    if( -not $section )
    {
        return
    }

    $flags = $flags -join ','
    $currentIntFlag = $section['sslFlags']
    $currentFlags = @( )
    if( $currentIntFlag -band $HttpsFlags_Https )
    {
        $currentFlags += 'Ssl'
    }
    if( $currentIntFlag -band $HttpsFlags_NegotiateCert )
    {
        $currentFlags += 'SslNegotiateCert'
    }
    if( $currentIntFlag -band $HttpsFlags_RequireCert )
    {
        $currentFlags += 'SslRequireCert'
    }
    if( $currentIntFlag -band $HttpsFlags_MapCert )
    {
        $currentFlags += 'SslMapCert'
    }
    if( $currentIntFlag -band $HttpsFlags_128Bit )
    {
        $currentFlags += 'Ssl128'
    }

    if( -not $currentFlags )
    {
        $currentFlags += 'None'
    }

    $currentFlags = $currentFlags -join ','

    if( $section['sslFlags'] -ne $intFlag )
    {
        $target = "IIS:$($section.LocationPath):$($section.SectionPath)"
        $infoMsg = "$($target)  sslFlags  $($section['sslFlags']) -> $($flags)"
        $section['sslFlags'] = $flags
        Save-CIisConfiguration -Target $target -Action 'Enable HTTPS' -Message $infoMsg
    }
}

