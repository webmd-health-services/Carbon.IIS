
enum CHttpResponseStatus
{
    Permanent = 301;
    Found = 302;
    Temporary = 307;
}

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

     Use the `GetAttributeValue` and `SetAttributeValue` to get and set values and the `CommitChanges` method to persist
     the changes to IIS.

    .LINK
    http://www.iis.net/configreference/system.webserver/httpredirect

    .EXAMPLE
    Get-CIisHttpRedirect -SiteName ExampleWebsite

    Gets the redirect settings for ExampleWebsite.

    .EXAMPLE
    Get-CIisHttpRedirect -SiteName ExampleWebsite -Path MyVirtualDirectory

    Gets the redirect settings for the MyVirtualDirectory virtual directory under ExampleWebsite.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        # The site's whose HTTP redirect settings will be retrieved.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The optional path to a sub-directory under `SiteName` whose settings to return.
        [String] $VirtualPath = ''
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-CIisConfigurationSection -SiteName $SiteName `
                                 -VirtualPath $VirtualPath `
                                 -SectionPath 'system.webServer/httpRedirect'
}
