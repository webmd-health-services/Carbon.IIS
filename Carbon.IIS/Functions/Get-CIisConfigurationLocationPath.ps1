
function Get-CIisConfigurationLocationPath
{
    <#
    .SYNOPSIS
    Gets the paths of all <location> element from applicationHost.config.

    .DESCRIPTION
    The `Get-CIisConfigurationLocationPath` function returns the paths for each `<location>` element in the
    applicationHost.config file. These location elements are where IIS stores custom configurations for websites and
    any paths under a website. If this function returns any values, then you know at least one site or site/path has
    custom configuration.

    To get the path for a specific website, pass its name to the `SiteName` parameter. If any path is returned, than
    that website has custom configuration.

    To get the path for a specific path under a website, pass the website name to the `SiteName` parameter and the
    path's virtual path to the `VirtualPath` parameter. If any path is returned, than that website/path has custom
    configuration.

    To get all paths under a website or website/path, use the `-Recurse` switch. If any paths are returned than that
    site has custom configuration somewhere in its hierarchy.

    .EXAMPLE
    Get-CIisConfigurationLocationPath

    Demonstrates how to get the path for each `<location>` element in the applicationHost.config file, i.e. the paths
    to each website and path under a website that has custom configuration.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -SiteName 'Default Web Site'

    Demonstrates how to get the location path for a specific site.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -SiteName 'Default Web Site' -VirtualPath 'some/path'

    Demonstrates how to get the location path for a specific virtual path under a specific website.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -SiteName 'Default Web Site' -Recurse

    Demonstrates how to get the location paths for all virtual paths including and under a specific website.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -SiteName 'Default Web Site' -VirtualPath 'some/path'

    Demonstrates how to get the location paths for all virtual paths including and under a specific virtual path under a
    specific website.
    #>
    [CmdletBinding()]
    param(
        # The name of a website whose location paths to get.
        [String] $SiteName,

        # The virtual path under the website whose location path to get.
        [String] $VirtualPath,

        # If true, returns all location paths under the website or website/virtual path provided.
        [switch] $Recurse
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = Get-CIisServerManager

    $locationPath = ''

    if( $SiteName )
    {
        $locationPath = $SiteName | ConvertTo-CIisVirtualPath -NoLeadingSlash
        if( $VirtualPath )
        {
            $locationPath = Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath
        }
    }

    $mgr.GetApplicationHostConfiguration().GetLocationPaths() |
        Where-Object { $_ } |
        Where-Object {
            return (-not $locationPath -or $_ -eq $locationPath -or ($Recurse -and $_ -like "$($locationPath)/*"))
        }
}
