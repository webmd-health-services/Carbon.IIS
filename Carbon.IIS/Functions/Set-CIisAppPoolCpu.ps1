
function Set-CIisAppPoolCpu
{
    <#
    .SYNOPSIS
    Configures an IIS application pool's CPU settings.

    .DESCRIPTION
    The `Set-CIisAppPoolCpu` configures an IIS application pool's CPU settings. Pass the application pool's name to the
    `AppPoolName` parameter. With no other parameters, the `Set-CIisAppPoolCpu` function removes all configuration from
    that application pool's CPU, which resets them to their defaults. To change a setting to a non-default value, pass
    the new value to its corresponding parameter. For each parameter that is *not* passed, its corresponding
    configuration is removed, which reset to that configuration to its default value.

    See [CPU Settings for an Application Pool](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/cpu)
    for more information.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/cpu

    .EXAMPLE
    Set-CIisAppPoolCpu -AppPoolName 'DefaultAppPool'

    Demonstrates how to reset an application pool's CPU settings to their default values by not passing any parameters
    except the application pool name to `Set-CIisAppPoolCpu`.

    .EXAMPLE
    Set-CIisAppPoolCpu -AppPoolName -DefaultAppPool -Limit 50000 -Action Throttle

    Demonstrates how to customize some of an application pool's CPU settings, while resetting all other configuration to
    their default values. In this example, the `limit` and `action` settings are set, and all other settings are
    removed, which resets them to their default values.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [String] $AppPoolName,

        [Microsoft.Web.Administration.ProcessorAction] $Action,

        [UInt32] $Limit,

        [CIisNumaNodeAffinityMode] $NumaNodeAffinityMode,

        [CIisNumaNodeAssignment] $NumaNodeAssignment,

        [int] $ProcessorGroup,

        [TimeSpan] $ResetInterval,

        [switch] $SmpAffinitized,

        [UInt32] $SmpProcessorAffinityMask,

        [UInt32] $SmpProcessorAffinityMask2
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $appPool = Get-CIisAppPool -Name $AppPoolName
    if( -not $appPool )
    {
        return
    }

    $attrs =
        $PSBoundParameters |
        Copy-Hashtable -Key ($appPool.Cpu.Schema.AttributeSchemas | Select-Object -ExpandProperty 'Name')

    $appPool.Cpu | Add-IisServerManagerMember -ServerManager $appPool.ServerManager

    $target = """$($AppPoolName)"" IIS Application Pool's CPU"
    Set-CIisConfigurationAttribute -Attribute $attrs -ConfigurationElement $appPool.Cpu -Target $target
}