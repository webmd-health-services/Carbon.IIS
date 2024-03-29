
function Uninstall-CIisVirtualDirectory
{
    <#
    .SYNOPSIS
    Delete an IIS virtual directory.

    .DESCRIPTION
    The `Uninstall-CIisVirtualDirectory` function deletes a virtual directory. Pass the virtual directory's site name to
    the `SiteName` parameter. Pass the virtual directory's virtual path to the `VirtualPath` parameter. If the virtual
    directory exists, it is deleted. If it doesn't exist, nothing happens. If the virtual directory is under an
    application, pass the application's path to the `ApplicationPath` parameter.

    The function will not delete a site's default, root application at virtual path `/` and will instead write an error.

    .EXAMPLE
    Uninstall-CIisVirtualDirectory -SiteName 'site' -VirtualPath '/some/vdir'

    Demonstrates how to use this function to delete an IIS virtual directory. In this example, the `/some/vdir` virtual
    directory under the `site` site will be removed, if it exists.

    .EXAMPLE
    Uninstall-CIisVirtualDirectory -SiteName 'site' -ApplicationPath 'app' -VirtualPath '/some/vdir'

    Demonstrates how to use this function to delete an IIS virtual directory that exists under an application. In this
    example, the `/some/vdir` virtual directory under the `site` site's '/app' app will be removed, if it exists.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        # The virtual directory's site.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The virtual directory's virtual path.
        [Parameter(Mandatory)]
        [Alias('Name')]
        [String] $VirtualPath,

        # The path of the virtual directory's application. The default is to look for the the virtual directory under
        # the site.
        [String] $ApplicationPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sites = Get-CIisWebsite -Name $SiteName
    if( -not $sites )
    {
        return
    }

    if (-not $ApplicationPath)
    {
        $ApplicationPath = '/'
    }

    $ApplicationPath = $ApplicationPath | ConvertTo-CIisVirtualPath

    $save = $false
    foreach ($site in $sites)
    {
        $app = $null
        $appDesc = ''

        $apps = Get-CIisApplication -SiteName $site.Name -VirtualPath $ApplicationPath
        if (-not $apps)
        {
            continue
        }

        foreach ($app in $apps)
        {
            $appDesc = ''
            $suggestedCmd = 'Uninstall-CIisWebsite'
            if ($app.Path -ne '/')
            {
                $appDesc = " under application ""$($app.Path)"""
                $suggestedCmd = 'Uninstall-CIisApplication'
            }

            $desc = "IIS virtual directory ""${VirtualPath}""${appDesc} under site ""$($site.Name)"""

            $vdirs = Get-CIisVirtualDirectory -SiteName $site.Name `
                                              -VirtualPath $VirtualPath `
                                              -ApplicationPath $ApplicationPath `
                                              -ErrorAction Ignore
            if (-not $vdirs)
            {
                Write-Verbose "${desc} does not exist."
                continue
            }

            foreach ($vdir in $vdirs)
            {
                $desc = "IIS virtual directory ""$($vdir.Path)""${appDesc} under site ""$($site.Name)"""
                if ($vdir.Path -eq '/')
                {
                    $msg = "Failed to delete ${desc} because it is the root, default virtual directory. Use the " +
                        """${suggestedCmd}"" function instead."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    continue
                }

                $vdirToDelete = $app.VirtualDirectories | Where-Object 'Path' -EQ $vdir.Path
                if (-not $vdirToDelete)
                {
                    Write-Verbose "${desc} does not exist."
                    continue
                }

                Write-Information "Deleting ${desc}."
                $app.VirtualDirectories.Remove($vdirToDelete)
                $save = $true
            }
        }
    }

    if ($save)
    {
        Save-CIisConfiguration
    }
}