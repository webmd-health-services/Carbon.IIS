
function Get-CIisApplication
{
    <#
    .SYNOPSIS
    Gets an IIS application as an `Application` object.

    .DESCRIPTION
    Uses the `Microsoft.Web.Administration` API to get an IIS application object.  If the application doesn't exist, `$null` is returned.

    If you make any changes to any of the objects returned by `Get-CIisApplication`, call `Save-CIisConfiguration` to
    save those changes to IIS.

    The objects returned each have a `PhysicalPath` property which is the physical path to the application.

    .OUTPUTS
    Microsoft.Web.Administration.Application.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar`

    Gets all the applications running under the `DeathStar` website.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar' -VirtualPath '/'

    Demonstrates how to get the main application for a website: use `/` as the application name.

    .EXAMPLE
    Get-CIisApplication -SiteName 'DeathStar' -VirtualPath 'MainPort/ExhaustPort'

    Demonstrates how to get a nested application, i.e. gets the application at `/MainPort/ExhaustPort` under the `DeathStar` website.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        # The site where the application is running.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The path/name of the application. Default is to return all applications running under the website given by
        # the `SiteName` parameter.
        [String] $VirtualPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $SiteName
    if( -not $site )
    {
        return
    }

    $VirtualPath = $VirtualPath | ConvertTo-CIisVirtualPath

    $site.Applications |
        Where-Object {
            if( $PSBoundParameters.ContainsKey('VirtualPath') )
            {
                return ($_.Path -eq $VirtualPath)
            }
            return $true
        }
}

