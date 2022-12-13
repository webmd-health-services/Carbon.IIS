
function Set-CIisWebsiteLimit
{
    <#
    .SYNOPSIS
    Configures an IIS website's limits settings.

    .DESCRIPTION
    The `Set-CIisWebsiteLimit` function configures an IIS website's limits settings. Pass the name of the website to the
     `SiteName` parameter. Pass the limits configuration to one or more of the ConnectionTimeout, MaxBandwidth,
     MaxConnections, and/or MaxUrlSegments parameters. See
    [Limits for a Web Site <limits>](https://learn.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/limits)
    for documentation on each setting.

    You can configure the IIS default website instead of a specific website by using the
    `AsDefaults` switch.

    If the `Reset` switch is set, each setting *not* passed as a parameter is deleted, which resets it to its default
    value.

    .LINK
    https://learn.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/limits

    .EXAMPLE
    Set-CIisWebsiteLimit -SiteName 'ExampleTwo' -ConnectionTimeout '00:01:00' -MaxBandwidth 2147483647 -MaxConnections 2147483647 -MaxUrlSegments 16

    Demonstrates how to configure all an IIS website's limits settings.

    .EXAMPLE
    Set-CIisWebsiteLimit -SiteName 'ExampleOne' -ConnectionTimeout 1073741823 -Reset

    Demonstrates how to set *all* an IIS website's limits settings (even if not passing all parameters) by using the
    `-Reset` switch. In this example, the `connectionTimeout` setting is set to `1073741823` and all other settings
    (`maxBandwidth`, `maxConnections`, and `maxUrlSegments`) are deleted, which resets them to their default values.

    .EXAMPLE
    Set-CIisWebsiteLimit -AsDefaults  -ConnectionTimeout 536870911

    Demonstrates how to configure the IIS website defaults limits settings by using the `AsDefaults` switch and not
    passing the website name.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the website whose limits settings to configure.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $SiteName,

        # If true, the function configures the IIS default website instead of a specific website.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS website's limits `connectionTimeout` setting.
        [TimeSpan] $ConnectionTimeout,

        # Sets the IIS website's limits `maxBandwidth` setting.
        [UInt32] $MaxBandwidth,

        # Sets the IIS website's limits `maxConnections` setting.
        [UInt32] $MaxConnections,

        # Sets the IIS website's limits `maxUrlSegments` setting.
        [UInt32] $MaxUrlSegments,

        # If set, each website limits setting *not* passed as a parameter is deleted, which resets it to its default
        # value.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $target = Get-CIisWebsite -Name $SiteName -Defaults:$AsDefaults
    if( -not $target )
    {
        return
    }

    $targetMsg = 'default IIS website limits'
    if( $SiteName )
    {
        $targetMsg = """$($SiteName)"" IIS website's limits"
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target.limits `
                                     -PSCmdlet $PSCmdlet `
                                     -Target $targetMsg `
                                     -Reset:$Reset
}
