
function Set-CIisWebsite
{
    <#
    .SYNOPSIS
    Configures an IIS website's settings.

    .DESCRIPTION
    The `Set-CIisWebsite` function configures an IIS website. Pass the name of the website to the `Name` parameter.
    Pass the website's ID to the `ID` parameter. If you want the server to not auto start, set `ServerAutoStart` to
    false: `-ServerAutoStart:$false` See [Site <site>](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/)
    for documentation on each setting.

    You can configure the IIS default website instead of a specific website by using the `AsDefaults` switch. Only the
    `serverAutoStart` setting can be set on IIS's default website settings.

    If any `ServerAutoStart` is not passed, it is not changed.

    If you use the `-Reset` switch and omit a `ServerAutoStart` argument, the `serverAutoStart` setting will be deleted,
    which will reset it to its default value.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/

    .EXAMPLE
    Set-CIisWebsite -SiteName 'ExampleTwo' -ID 53 -ServerAutoStart $false

    Demonstrates how to configure an IIS website's settings.

    .EXAMPLE
    Set-CIisWebsite -SiteName 'ExampleOne' -ID 53 -Reset

    Demonstrates how to set *all* an IIS website's settings by using the `-Reset` switch. In this example, the `id`
    setting is set to a custom value, and the `serverAutoStart` (the only other website setting) is deleted, which
    resets it to its default value.

    .EXAMPLE
    Set-CIisWebsite -AsDefaults -ServerAutoStart:$false

    Demonstrates how to configure the IIS default website's settings by using the `AsDefaults` switch and not passing
    the website name.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the website whose settings to configure.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $Name,

        # If true, the function configures the IIS default website instead of a specific website.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS website's `id` setting. Can not be used when setting site defaults.
        [Parameter(ParameterSetName='SetInstance')]
        [UInt32] $ID,

        # Sets the IIS website's `serverAutoStart` setting.
        [bool] $ServerAutoStart,

        # If set, the website setting for each parameter *not* passed is deleted, which resets it to its default value.
        # Otherwise, website settings whose parameters are not passed are left in place and not modified.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $target = Get-CIisWebsite -Name $Name -Defaults:$AsDefaults
    if( -not $target )
    {
        return
    }

    $attribute = @{}
    # Can't ever remove a site's ID, only change it (i.e. it must always be set to something). If user doesn't pass it,
    # set it to the website's current ID.
    if( -not $PSBoundParameters.ContainsKey('ID') -and ($target | Get-Member -Name 'Id') )
    {
        $attribute['ID'] = $target.Id
    }

    $targetMsg = 'IIS website defaults'
    if( $Name )
    {
        $targetMsg = "IIS website ""$($Name)"""
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target `
                                     -PSCmdlet $PSCmdlet `
                                     -Target $targetMsg `
                                     -Exclude @('state') `
                                     -Attribute $attribute `
                                     -Reset:$Reset `
                                     -Defaults (Get-CIIsWebsite -Defaults) `
                                     -AsDefaults:$AsDefaults
}
