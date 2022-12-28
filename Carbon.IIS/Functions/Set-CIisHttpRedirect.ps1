
function Set-CIisHttpRedirect
{
    <#
    .SYNOPSIS
    Turns on HTTP redirect for all or part of a website.

    .DESCRIPTION
    Configures all or part of a website to redirect all requests to another website/URL. Pass the virtual/location path
    to the website, application, virtual directory, or directory to configure to the `LocationPath` parameter. Pass the
    redirect destination to the `Destination` parameter. Pass the redirect HTTP response status code to the
    `HttpResponseStatus`. Pass `$true` or `$false` to the `ExactDestination` parameter. Pass `$true` or `$false` to the
    `ChildOnly` parameter.

    For each parameter that isn't provided, the current value of that attribute is not changed. To delete any attributes
    whose parameter isn't passed, use the `Reset` switch. Deleting an attribute resets it to its default value.

    .LINK
    http://www.iis.net/configreference/system.webserver/httpredirect#005

    .LINK
    http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx

    .EXAMPLE
    Set-CIisHttpRedirect -LocationPath Peanuts -Destination 'http://new.peanuts.com'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-CIisHttpRedirect -LocationPath 'Peanuts/Snoopy/DogHouse' -Destination 'http://new.peanuts.com'

    Redirects all requests to the `/Snoopy/DogHouse` path on the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-CIisHttpRedirect -LocationPath Peanuts -Destination 'http://new.peanuts.com' -StatusCode 'Temporary'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com` with a temporary HTTP status code.  You
    can also specify `Found` (HTTP 302), `Permanent` (HTTP 301), or `PermRedirect` (HTTP 308).

    .EXAMPLE
    Set-CIisHttpRedirect -LocationPath 'Peanuts' -Destination 'http://new.peanuts.com' -StatusCode 'Temporary' -Reset

    Demonstrates how to reset the attributes for any parameter that isn't passed to its default value by using the
    `Reset` switch. In this example, the `exactDestination` and `childOnly` HTTP redirect attributes are deleted and
    reset to their default value because they aren't being passed as arguments.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The site where the redirection should be setup.
        [Parameter(Mandatory, Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

        # If true, enables HTTP redirect. Otherwise, disables it.
        [bool] $Enabled,

        # The destination to redirect to.
        [Parameter(Mandatory)]
        [String] $Destination,

        # The HTTP status code to use.  Default is `Found` (`302`).  Should be one of `Permanent` (`301`),
        # `Found` (`302`), `Temporary` (`307`), or `PermRedirect` (`308`). This is stored in IIS as a number.
        [Alias('StatusCode')]
        [CIisHttpRedirectResponseStatus] $HttpResponseStatus,

        # Redirect all requests to exact destination (instead of relative to destination).
        [bool] $ExactDestination,

        # Only redirect requests to content in site and/or path, but nothing below it.
        [bool] $ChildOnly,

        # If set, the HTTP redirect setting for each parameter *not* passed is deleted, which resets it to its default
        # value. Otherwise, HTTP redirect settings whose parameters are not passed are left in place and not modified.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($VirtualPath)
    {
        Write-CIisWarningOnce -ForObsoleteSiteNameAndVirtualPathParameter
    }

    $attrs =
        $PSBoundParameters |
        Copy-Hashtable -Key @('enabled', 'destination', 'httpResponseStatus', 'exactDestination', 'childOnly')

    Set-CIisConfigurationAttribute -LocationPath ($LocationPath, $VirtualPath | Join-CIisPath) `
                                   -SectionPath 'system.webServer/httpRedirect' `
                                   -Attribute $attrs `
                                   -Reset:$Reset
}
