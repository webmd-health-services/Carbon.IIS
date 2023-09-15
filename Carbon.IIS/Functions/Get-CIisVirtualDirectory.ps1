
function Get-CIisVirtualDirectory
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
    [OutputType([Microsoft.Web.Administration.VirtualDirectory])]
    param(
        # The site where the application is running.
        [Parameter(Mandatory, Position=0, ParameterSetName='ByLocationPath')]
        [String] $LocationPath,

        # The virtual directory's site's name.
        [Parameter(Mandatory, ParameterSetName='ByName')]
        [String] $SiteName,

        # The virtual directory's virtual path. Wildcards supported.
        [Parameter(ParameterSetName='ByName')]
        [String] $VirtualPath,

        # The virtual directory's application's virtual path. The default is to get the root site's virtual directories.
        [Parameter(ParameterSetName='ByName')]
        [String] $ApplicationPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $sites = Get-CIisWebsite -Name $SiteName
        if (-not $sites)
        {
            return
        }

        if (-not $ApplicationPath)
        {
            $ApplicationPath = '/'
        }

        $VirtualPath = $VirtualPath | ConvertTo-CIisVirtualPath

        foreach ($site in $sites)
        {
            $apps = Get-CIisApplication -SiteName $site.Name -VirtualPath $ApplicationPath
            if (-not $apps)
            {
                continue
            }

            foreach ($app in $apps)
            {
                $appDesc = ''
                if ($app.Path -ne '/')
                {
                    $appDesc = " under application ""$($app.Path)"""
                }

                $vdir =
                    $app.VirtualDirectories |
                    Where-Object {
                        if ($VirtualPath)
                        {
                            return $_.Path -like $VirtualPath
                        }

                        return $true
                    }
                if (-not $vdir)
                {
                    if ($VirtualPath -and -not [wildcardpattern]::ContainsWildcardCharacters($VirtualPath))
                    {
                        $msg = "Failed to get virtual directory ""${VirtualPath}""${appDesc} under site " +
                               """${SiteName}"" because the virtual directory does not exist."
                        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    }
                    continue
                }

                $vdir | Write-Output
            }
        }

        return
    }

    $siteName, $virtualPath = $LocationPath | Split-CIisLocationPath

    $site = Get-CIisWebsite -Name $siteName
    if( -not $site )
    {
        return
    }

    $virtualPath = $virtualPath | ConvertTo-CIisVirtualPath

    foreach ($app in $site.Applications)
    {
        foreach ($vdir in $app.VirtualDirectories)
        {
            $fullVirtualPath = Join-CIisPath $app.Path, $vdir.Path -LeadingSlash

            if ($fullVirtualPath -like $virtualPath)
            {
                $vdir | Write-Output
            }
        }
    }
}

