
function Set-CIisAppPool
{
    <#
    .SYNOPSIS
    Configures an IIS application pool's settings.

    .DESCRIPTION
    The `Set-CIisAppPool` function configures an IIS application pool's settings. Pass the name of
    the application pool to the `Name` parameter. Pass the configuration you want to one
    or more of the AutoStart, CLRConfigFile, Enable32BitAppOnWin64, EnableConfigurationOverride, ManagedPipelineMode,
    ManagedRuntimeLoader, ManagedRuntimeVersion, Name, PassAnonymousToken, QueueLength, and/or StartMode parameters. See
    [Adding Application Pools <add>](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/)
    for documentation on each setting.

    You can configure the IIS application pool defaults instead of a specific application pool by using the
    `AsDefaults` switch.

    If you want to ensure that any settings that may have gotten changed by hand are reset to their default values, use
    the `-Reset` switch. When set, the `-Reset` switch will reset each setting not passed as an argument to its default
    value.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/

    .EXAMPLE
    Set-CIisAppPool -AppPoolName 'ExampleTwo' -Enable32BitAppOnWin64 $true -ManagedPipelineMode Classic

    Demonstrates how to configure an IIS application pool's settings. In this example, the app pool will be updated to
    run as a 32-bit applicaiton and will use a classic pipeline mode. All other settings are left unchanged.

    .EXAMPLE
    Set-CIisAppPool -AppPoolName 'ExampleOne' -Enable32BitAppOnWin64 $true -ManagedPipelineMode Classic -Reset

    Demonstrates how to reset an IIS application pool's settings to their default values by using the `-Reset` switch. In
    this example, the `enable32BitAppOnWin64` and `managedPipelineMode` settings are set to `true` and `Classic`, and
    all other application pool settings are deleted, which reset them to their default values.

    .EXAMPLE
    Set-CIisAppPool -AsDefaults -Enable32BitAppOnWin64 $true -ManagedPipelineMode Classic

    Demonstrates how to configure the IIS application pool defaults settings by using
    the `AsDefaults` switch and not passing application pool name. In this case, all future application pools created
    will be 32-bit applications and use a classic pipeline mode, unless those settings are configured differently upon
    install.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the application pool whose settings to configure.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $Name,

        # If true, the function configures the IIS application pool defaults instead of a specific application pool.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS application pool's `autoStart` setting.
        [bool] $AutoStart,

        # Sets the IIS application pool's `CLRConfigFile` setting.
        [String] $CLRConfigFile,

        # Sets the IIS application pool's `enable32BitAppOnWin64` setting.
        [bool] $Enable32BitAppOnWin64,

        # Sets the IIS application pool's `enableConfigurationOverride` setting.
        [bool] $EnableConfigurationOverride,

        # Sets the IIS application pool's `managedPipelineMode` setting.
        [ManagedPipelineMode] $ManagedPipelineMode,

        # Sets the IIS application pool's `managedRuntimeLoader` setting.
        [String] $ManagedRuntimeLoader,

        # Sets the IIS application pool's `managedRuntimeVersion` setting.
        [String] $ManagedRuntimeVersion,

        # Sets the IIS application pool's `passAnonymousToken` setting.
        [bool] $PassAnonymousToken,

        # Sets the IIS application pool's `queueLength` setting.
        [UInt32] $QueueLength,

        # Sets the IIS application pool's `startMode` setting.
        [StartMode] $StartMode,

        # Resets *all* the application pool's settings to their default values, *except* each setting whose
        # cooresponding parameter is passed. The default behavior is to only modify each setting whose corresponding
        # parameter is passed.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $target = Get-CIisAppPool -Name $Name -Defaults:$AsDefaults
    if( -not $target )
    {
        return
    }

    $targetMsg = 'IIS application pool defaults'
    if( $Name )
    {
        $targetMsg = "IIS application pool ""$($Name)"""
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target `
                                     -PSCmdlet $PSCmdlet `
                                     -Target $targetMsg `
                                     -Attribute @{ 'name' = $Name } `
                                     -Exclude @('applicationPoolSid', 'state') `
                                     -Reset:$Reset
}
