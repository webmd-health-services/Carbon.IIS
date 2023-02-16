
function Set-CIisAppPoolRecycling
{
    <#
    .SYNOPSIS
    Configures an IIS application pool's recycling settings.

    .DESCRIPTION
    The `Set-CIisAppPoolRecycling` function configures an IIS application pool's recycling settings. Pass the name of
    the application pool to the `AppPoolName` parameter. Pass the recycling configuration you want to one or more of the
    DisallowOverlappingRotation, DisallowRotationOnConfigChange, and/or LogEventOnRecycle parameters. See
    [Recycling Settings for an Application Pool <recycling>](https://learn.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/recycling/)
    for documentation on each setting.

    You can configure the IIS default application pool instead of a specific application pool by using the `AsDefaults`
    switch.

    If the `Reset` switch is set, each setting *not* passed as a parameter is deleted, which resets it to its default
    values.

    .LINK
    https://learn.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/recycling/

    .EXAMPLE
    Set-CIisAppPoolRecycling -AppPoolName 'ExampleTwo' -DisallowOverlappingRotation $true -DisallowRotationOnConfigChange $true -LogEventOnRecycle None

    Demonstrates how to configure all an IIS application pool's recycling settings.

    .EXAMPLE
    Set-CIisAppPoolRecycling -AppPoolName 'ExampleOne' -DisallowOverlappingRotation $true -Reset

    Demonstrates how to set *all* an IIS application pool's recycling settings (even if not passing all parameters) by
    using the `-Reset` switch. In this example, the disallowOverlappingRotation setting is set to `$true`, and the
    `disallowRotationOnConfigChange` and `LogEventOnRecycle` settings are deleted, which resets them to their default
    values.

    .EXAMPLE
    Set-CIisAppPoolRecycling -AsDefaults -LogEventOnRecycle None

    Demonstrates how to configure the IIS application pool defaults recycling settings by using the `AsDefaults` switch
    and not passing the application pool name. In this example, the default application pool `logEventOnRecycle` recycle
    setting will be set to `None`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the application pool whose recycling settings to configure.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $AppPoolName,

        # If true, the function configures the IIS default application pool instead of a specific application pool.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS application pool's recycling `disallowOverlappingRotation` setting.
        [bool] $DisallowOverlappingRotation,

        # Sets the IIS application pool's recycling `disallowRotationOnConfigChange` setting.
        [bool] $DisallowRotationOnConfigChange,

        # Sets the IIS application pool's recycling `logEventOnRecycle` setting.
        [RecyclingLogEventOnRecycle] $LogEventOnRecycle,

        # If set, each application pool recycling setting *not* passed as a parameter is deleted, which resets it to its
        # default value.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getArgs = @{}
    if ($AppPoolName)
    {
        $getArgs['Name'] = $AppPoolName
    }
    elseif ($AsDefaults)
    {
        $getArgs['Defaults'] = $true
    }

    $target = Get-CIisAppPool @getArgs
        if( -not $target )
    {
        return
    }

    $targetMsg = 'default IIS application pool recycling'
    if( $AppPoolName )
    {
        $targetMsg = """$($AppPoolName)"" IIS application pool's recycling"
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target.recycling `
                                     -PSCmdlet $PSCmdlet `
                                     -Target $targetMsg `
                                     -Reset:$Reset `
                                     -Defaults (Get-CIIsAppPool -Defaults).Recycling `
                                     -AsDefaults:$AsDefaults
}
