
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

    To get the path for a specific website, directory, application, or virtual directory, pass its location path to the
    `LocationPath` parameter.

    To get all paths under a website or website/path, use the `-Recurse` switch. If any paths are returned then that
    site has custom configuration somewhere in its hierarchy.

    .EXAMPLE
    Get-CIisConfigurationLocationPath

    Demonstrates how to get the path for each `<location>` element in the applicationHost.config file, i.e. the paths
    to each website and path under a website that has custom configuration.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -LocationPath 'Default Web Site'

    Demonstrates how to get the location path for a specific site.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -LocationPath 'Default Web Site/some/path'

    Demonstrates how to get the location path for a specific virtual path under a specific website.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -LocationPath 'Default Web Site' -Recurse

    Demonstrates how to get the location paths for all virtual paths including and under a specific website.

    .EXAMPLE
    Get-CIisConfigurationLocationPath -LocationPath 'Default Web Site/some/path'

    Demonstrates how to get the location paths for all virtual paths including and under a specific virtual path under a
    specific website.
    #>
    [CmdletBinding()]
    param(
        # The name of a website whose location paths to get.
        [Parameter(Position=0)]
        [String] $LocationPath,

        # If true, returns all location paths under the website or website/virtual path provided.
        [switch] $Recurse
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $LocationPath = $LocationPath | ConvertTo-CIisVirtualPath -NoLeadingSlash

    $mgr = Get-CIisServerManager
    $mgr.GetApplicationHostConfiguration().GetLocationPaths() |
        Where-Object { $_ } |
        Where-Object {
            return (-not $LocationPath -or $_ -eq $LocationPath -or ($Recurse -and $_ -like "$($LocationPath)/*"))
        }
}
