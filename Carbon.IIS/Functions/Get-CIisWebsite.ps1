
function Get-CIisWebsite
{
    <#
    .SYNOPSIS
    Returns all the websites installed on the local computer, a specific website, or website defaults.

    .DESCRIPTION
    The `Get-CIisWebsite` function returns all websites installed on the local computer, or nothing if no websites are
    installed. To get a specific website, pass its name to the `Name` parameter. If a website with that name exists, it
    is returned as a `Microsoft.Web.Administration.Site` object, from the Microsoft.Web.Administration API. If the
    website doesn't exist, the function will write an error and return nothing.

    You can get the default settings for websites by using the `Defaults` switch. If `Defaults` is true, then the `Name`
    parameter is ignored.

    If you make any changes to any of the return objects, use `Save-CIisConfiguration` to save your changes.

    .OUTPUTS
    Microsoft.Web.Administration.Site.

    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.site.aspx

    .EXAMPLE
    Get-CIisWebsite

    Returns all installed websites.

    .EXAMPLE
    Get-CIisWebsite -Name 'WebsiteName'

    Returns the details for the site named `WebsiteName`.

    .EXAMPLE
    Get-CIisWebsite -Name 'fubar' -ErrorAction Ignore

    Demonstrates how to ignore that a website doesn't exist by setting the `ErrorAction` parameter to `Ignore`.

    .EXAMPLE
    Get-CIisWebsite -Defaults

    Demonstrates how to get IIS default website settings.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        # The name of the site to get.
        [String] $Name,

        # Instead of getting all websites or a specifid website, return default website settings. If true, the `Name`
        # parameter is ignored.
        [switch] $Defaults
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $Defaults )
    {
        return (Get-CIisServerManager).SiteDefaults
    }

    if( $Name -and -not (Test-CIisWebsite -Name $Name) )
    {
        Write-Error -Message "Website ""$($Name)"" does not exist." -ErrorAction $ErrorActionPreference
        return
    }

    $mgr = Get-CIisServerManager
    $mgr.Sites |
        Where-Object {
            if( $Name )
            {
                return $_.Name -eq $Name
            }

            return $true
        }
}

