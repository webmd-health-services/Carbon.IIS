
function Uninstall-CIisApplication
{
    <#
    .SYNOPSIS
    Delete an IIS application.

    .DESCRIPTION
    The `Uninstall-CIisApplication` function deletes an application. Pass the application's site name to the `SiteName`
    parameter. Pass the application's virtual path to the `VirtualPath` parameter. If the application exists, it is
    deleted. If it doesn't exist, nothing happens.

    The function will not delete a site's default, root application at virtual path `/` and will instead write an error.

    .EXAMPLE
    Uninstall-CIisApplication -SiteName 'site' -VirtualPath '/some/app'

    Demonstrates how to use this function to delete an IIS application. In this example, the `/some/app` application
    under the `site` site will be removed, if it exists.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        # The applicatoin's site.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The application's virtual path.
        [Parameter(Mandatory)]
        [Alias('Name')]
        [String] $VirtualPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sites = Get-CIisWebsite -Name $SiteName
    if( -not $sites )
    {
        return
    }

    $save = $false
    foreach ($site in $sites)
    {
        $apps = Get-CIisApplication -SiteName $site.Name -VirtualPath $VirtualPath
        if (-not $apps)
        {
            Write-Verbose "IIS application ""${VirtualPath}"" under site ""$($site.Name)"" does not exist."
            continue
        }

        foreach ($app in $apps)
        {
            if ($app.Path -eq '/')
            {
                $msg = "Failed to delete IIS application ""$($app.Path)}"" under site ""$($site.Name)"" because it " +
                       'is the root, default application. Use the "Uninstall-CIisWebsite" function to uninstall IIS ' +
                       'sites.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                continue
            }

            Write-Information "Deleting IIS application ""$($app.Path)"" under site ""$($site.Name)""."
            $apps = Get-CIisCollection -ConfigurationElement $site
            $appToRemove = $apps | Where-Object { $_.GetAttributeValue('path') -eq $app.Path }
            $apps.Remove($appToRemove)
            $save = $true
        }
    }

    if ($save)
    {
        Save-CIisConfiguration
    }
}