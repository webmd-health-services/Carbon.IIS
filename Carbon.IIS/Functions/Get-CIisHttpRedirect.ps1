

function Get-CIisHttpRedirect
{
    <#
    .SYNOPSIS
    Gets the HTTP redirect settings for a website or virtual directory/application under a website.

    .DESCRIPTION
    Returns a `[Microsoft.Web.Administration.ConfigurationSection]` object with these attributes:

     * enabled - `True` if the redirect is enabled, `False` otherwise.
     * destination - The URL where requests are directed to.
     * httpResponseCode - The HTTP status code sent to the browser for the redirect.
     * exactDestination - `True` if redirects are to destination, regardless of the request path.  This will send all
     requests to `Destination`.
     * childOnly - `True` if redirects are only to content in the destination directory (not subdirectories).

     Use the `GetAttributeValue` and `SetAttributeValue` to get and set values and the `Save-CIisConfiguration` function
     to save the changes to IIS.

    .LINK
    http://www.iis.net/configreference/system.webserver/httpredirect

    .EXAMPLE
    Get-CIisHttpRedirect -LocationPath 'ExampleWebsite'

    Gets the redirect settings for ExampleWebsite.

    .EXAMPLE
    Get-CIisHttpRedirect -LocationPath 'ExampleWebsite/MyVirtualDirectory'

    Gets the redirect settings for the MyVirtualDirectory virtual directory under ExampleWebsite.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        # The site's whose HTTP redirect settings will be retrieved.
        [Parameter(Mandatory)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sectionPath = 'system.webServer/httpRedirect'
    Get-CIisConfigurationSection -LocationPath $LocationPath -VirtualPath $VirtualPath -SectionPath $sectionPath
}
