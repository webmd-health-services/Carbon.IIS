
function Set-CIisAppPoolCpu
{
    <#
    .SYNOPSIS
    Configures IIS application pool CPU settings.

    .DESCRIPTION
    The `Set-CIisAppPoolCpu` configures an IIS application pool's CPU settings. Pass the application pool's name to the
    `AppPoolName` parameter. With no other parameters, the `Set-CIisAppPoolCpu` function removes all configuration from
    that application pool's CPU, which resets them to their defaults. To change a setting to a non-default value, pass
    the new value to its corresponding parameter. For each parameter that is *not* passed, its corresponding
    configuration is removed, which reset that configuration to its default value. See
    [CPU Settings for an Application Pool <cpu>](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/cpu)
    for documentation on each setting.

    You can configure IIS's application pool defaults instead of a specific application pool's settings by using the
    `AsDefaults` switch.

    If you want to ensure that any settings that may have gotten changed by hand are reset to their default values, use
    the `-Reset` switch. When set, the `-Reset` switch will reset each setting not passed as an argument to its default
    value.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/cpu

    .EXAMPLE
    Set-CIisAppPoolCpu -AppPoolName -DefaultAppPool -Limit 50000 -Action Throttle

    Demonstrates how to customize some of an application pool's CPU settings, while resetting all other configuration to
    their default values. In this example, the `limit` and `action` settings are set, and all other settings are
    removed, which resets them to their default values.

    .EXAMPLE
    Set-CIisAppPoolCpu -AppPoolName 'DefaultAppPool' -Limit 50000 -Action Throttle -Reset

    Demonstrates how to set *all* an IIS application pool's CPU settings by using the `-Reset` switch. In this example,
    the `limit` and `throttle` settings are set to custom values, and all other settings are deleted, which resets them
    to their default values.

    .EXAMPLE
    Set-CIisAppPool -AsDefaults -Limit 50000 -ActionThrottle

    Demonstrates how to configure the IIS application pool defaults CPU settings by using the `-AsDefaults` switch and
    not passing an application pool name.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $AppPoolName,

        # If true, the function configures IIS' application pool defaults instead of
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # The value for the application pool's `action` CPU setting.
        [ProcessorAction] $Action,

        # The value for the application pool's `limit` CPU setting.
        [UInt32] $Limit,

        # The value for the application pool's `numaNodeAffinityMode` CPU setting.
        [CIisNumaNodeAffinityMode] $NumaNodeAffinityMode,

        # The value for the application pool's `numaNodeAssignment` CPU setting.
        [CIisNumaNodeAssignment] $NumaNodeAssignment,

        # The value for the application pool's `processorGroup` CPU setting.
        [int] $ProcessorGroup,

        # The value for the application pool's `resetInterval` CPU setting.
        [TimeSpan] $ResetInterval,

        # The value for the application pool's `smpAffinitized` CPU setting.
        [bool] $SmpAffinitized,

        # The value for the application pool's `smpProcessorAffinityMask` CPU setting.
        [UInt32] $SmpProcessorAffinityMask,

        # The value for the application pool's `smpProcessorAffinityMask2` CPU setting.
        [UInt32] $SmpProcessorAffinityMask2,

        # If set, the application pool CPU setting for each parameter *not* passed is deleted, which resets it to its
        # default value. Otherwise, application pool CPU settings whose parameters are not passed are left in place and
        # not modified.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $AppPoolName -Defaults:$AsDefaults
    if( -not $appPool )
    {
        return
    }

    $target = 'IIS application pool defaults CPU'
    if( $AppPoolName )
    {
        $target = """$($AppPoolName)"" IIS application pool's CPU"
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $appPool.Cpu -PSCmdlet $PSCmdlet -Target $target -Reset:$Reset
}