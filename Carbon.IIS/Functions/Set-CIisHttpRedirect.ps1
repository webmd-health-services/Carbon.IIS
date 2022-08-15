
function Set-CIisHttpRedirect
{
    <#
    .SYNOPSIS
    Turns on HTTP redirect for all or part of a website.

    .DESCRIPTION
    Configures all or part of a website to redirect all requests to another website/URL.  By default, it operates on a
    specific website.  To configure a directory under a website, set `VirtualPath` to the virtual path of that
    directory.

    For each parameter that isn't provided, that parmaeter's value will be reset to the IIS default value.

    .LINK
    http://www.iis.net/configreference/system.webserver/httpredirect#005

    .LINK
    http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx

    .EXAMPLE
    Set-CIisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-CIisHttpRedirect -SiteName Peanuts -VirtualPath Snoopy/DogHouse -Destination 'http://new.peanuts.com'

    Redirects all requests to the `/Snoopy/DogHouse` path on the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-CIisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com' -StatusCode 'Temporary'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com` with a temporary HTTP status code.  You
    can also specify `Found` (HTTP 302), or `Permanent` (HTTP 301).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The site where the redirection should be setup.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The optional path where redirection should be setup.
        [String] $VirtualPath = '',

        # The destination to redirect to.
        [Parameter(Mandatory)]
        [String] $Destination,

        # The HTTP status code to use.  Default is `Found`.  Should be one of `301` (`Permanent`), `302` (`Found`), or
        # `307` (`Temporary`).
        [Alias('StatusCode')]
        [ValidateSet(301, 302, 307)]
        [int] $HttpResponseStatus = 302,

        # Redirect all requests to exact destination (instead of relative to destination).  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
        [switch] $ExactDestination,

        # Only redirect requests to content in site and/or path, but nothing below it.  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
        [switch] $ChildOnly
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Set-CIisConfigurationAttribute -SiteName $SiteName `
                                   -VirtualPath $VirtualPath `
                                   -SectionPath 'system.webServer/httpRedirect' `
                                   -Attribute @{
                                        'enabled' = $true;
                                        'destination' = $destination;
                                        'httpResponseStatus' = $HttpResponseStatus;
                                        'exactDestination' = [bool]$ExactDestination;
                                        'childOnly' = [bool]$ChildOnly;
                                    }
}

