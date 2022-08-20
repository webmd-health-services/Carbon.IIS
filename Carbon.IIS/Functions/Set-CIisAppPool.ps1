
function Set-CIisAppPool
{
    <#
    .SYNOPSIS
    Configures an IIS application pool's settings.

    .DESCRIPTION
    The `Set-CIisAppPool` function configures an IIS application pool's settings. Pass the name of
    the application pool to the `AppPoolName` parameter. Pass the configuration you want to one
    or more of the AutoStart, CLRConfigFile, Enable32BitAppOnWin64, EnableConfigurationOverride, ManagedPipelineMode, ManagedRuntimeLoader, ManagedRuntimeVersion, Name, PassAnonymousToken, QueueLength, and/or StartMode parameters. See
    [Adding Application Pools <add>](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/)
    for documentation on each setting.

    You can configure the IIS default application pool instead of a specific application pool by using the
    `Defaults` switch.

    If any parameters are not passed, those settings will be reset to their default values.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/

    .EXAMPLE
    Set-CIisAppPool -AppPoolName 'ExampleOne'

    Demonstrates how to reset an IIS application pool's settings to their default
    values by not passing any arguments.

    .EXAMPLE
    Set-CIisAppPool -AppPoolName 'ExampleTwo' %EXAMPLE_ARGUMENTS%

    Demonstrates how to configure an IIS application pool's settings.

    .EXAMPLE
    Set-CIisAppPool -AsDefaults %EXAMPLE_ARGUMENTS%

    Demonstrates how to configure the IIS default application pool's settings by using
    the `AsDefaults` switch and not passing application pool name.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the application pool whose settings to configure.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $AppPoolName,

        # If true, the function configures the IIS default application pool instead of a specific application pool.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS application pool's `autoStart` setting.
        [switch] $AutoStart,

        # Sets the IIS application pool's `CLRConfigFile` setting.
        [String] $CLRConfigFile,

        # Sets the IIS application pool's `enable32BitAppOnWin64` setting.
        [switch] $Enable32BitAppOnWin64,

        # Sets the IIS application pool's `enableConfigurationOverride` setting.
        [switch] $EnableConfigurationOverride,

        # Sets the IIS application pool's `managedPipelineMode` setting.
        [ManagedPipelineMode] $ManagedPipelineMode,

        # Sets the IIS application pool's `managedRuntimeLoader` setting.
        [String] $ManagedRuntimeLoader,

        # Sets the IIS application pool's `managedRuntimeVersion` setting.
        [String] $ManagedRuntimeVersion,

        # Sets the IIS application pool's `passAnonymousToken` setting.
        [switch] $PassAnonymousToken,

        # Sets the IIS application pool's `queueLength` setting.
        [UInt32] $QueueLength,

        # Sets the IIS application pool's `startMode` setting.
        [StartMode] $StartMode
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $target = Get-CIisAppPool -Name $AppPoolName -Defaults:$AsDefaults
    if( -not $target )
    {
        return
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target `
                                     -PSCmdlet $PSCmdlet `
                                     -Target "IIS application pool ""$($AppPoolName)""" `
                                     -Attribute @{ 'name' = $AppPoolName } `
                                     -Exclude @('applicationPoolSid', 'state')
}
