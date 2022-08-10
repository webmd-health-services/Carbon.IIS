
function Get-CIisWebsite
{
    <#
    .SYNOPSIS
    Returns all the websites installed on the local computer, or a specific website.

    .DESCRIPTION
    The `Get-CIisWebsite` function returns all websites installed on the local computer, or nothing if no websites are
    installed. To get a specific website, pass its name to the `Name` parameter. If a website with that name exists, it
    is returned as a `Microsoft.Web.Administration.Site` object, from the Microsoft.Web.Administration API. If the
    website doesn't exist, the function will write an error and return nothing.

    Each object will have a `CommitChanges` script method added which will allow you to commit/persist any changes to
    the website's configuration.

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
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        # The name of the site to get.
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $Name -and -not (Test-CIisWebsite -Name $Name) )
    {
        Write-Error -Message "Website ""$($Name)"" does not exist." -ErrorAction $ErrorActionPreference
        return
    }

    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $mgr.Sites |
        Where-Object {
            if( $Name )
            {
                $_.Name -eq $Name
            }
            else
            {
                $true
            }
        } | Add-IisServerManagerMember -ServerManager $mgr -PassThru
}

