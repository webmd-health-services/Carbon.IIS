
function Set-CIisAppPoolProcessModel
{
    <#
    .SYNOPSIS
    Configures an IIS application pool's process model settings.

    .DESCRIPTION
    The `Set-CIisAppPoolProcessModel` function configures an IIS application pool's process model settings. Pass the
    name of the application pool to the `AppPoolName` parameter. Pass the process model configuration you want to one
    or more of the IdentityType, IdleTimeout, IdleTimeoutAction, LoadUserProfile, LogEventOnProcessModel, LogonType, ManualGroupMembership, MaxProcesses, Password, PingingEnabled, PingInterval, PingResponseTime, RequestQueueDelegatorIdentity, SetProfileEnvironment, ShutdownTimeLimit, StartupTimeLimit, and/or UserName parameters. See
    [Process Model Settings for an Application Pool <processModel>](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/processmodel)
    for documentation on each setting.

    You can configure the IIS default application pool instead of a specific application pool by using the
    `Defaults` switch.

    If any parameters are not passed, those settings will be reset to their default values.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/processmodel

    .EXAMPLE
    Set-CIisAppPoolProcessModel -AppPoolName 'ExampleOne'

    Demonstrates how to reset an IIS application pool's process model settings to their default
    values by not passing any arguments.

    .EXAMPLE
    Set-CIisAppPoolProcessModel -AppPoolName 'ExampleTwo' -UserName 'user1' -Password $password

    Demonstrates how to set an IIS application pool to run as a custom identity. In this example, the application pool
    is updated to run as the user `user1`. All other process model settings are reset to their defaults.

    .EXAMPLE
    Set-CIisAppPoolProcessModel -AsDefaults -IdleTimeout '00:00:00'

    Demonstrates how to configure the IIS default application pool's process model settings by using
    the `AsDefaults` switch and not passing application pool name. In this example, the default application pool's
    idleTimeout setting is set to `00:00:00` and all other settings are reset to their default values.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the application pool whose process model settings to set.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $AppPoolName,

        # If true, the function configures the IIS default application pool instead of a specific application pool.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS application pool's process model `identityType` setting.
        [ProcessModelIdentityType] $IdentityType,

        # Sets the IIS application pool's process model `idleTimeout` setting.
        [TimeSpan] $IdleTimeout,

        # Sets the IIS application pool's process model `idleTimeoutAction` setting.
        [IdleTimeoutAction] $IdleTimeoutAction,

        # Sets the IIS application pool's process model `loadUserProfile` setting.
        [switch] $LoadUserProfile,

        # Sets the IIS application pool's process model `logEventOnProcessModel` setting.
        [ProcessModelLogEventOnProcessModel] $LogEventOnProcessModel,

        # Sets the IIS application pool's process model `logonType` setting.
        [CIisProcessModelLogonType] $LogonType,

        # Sets the IIS application pool's process model `manualGroupMembership` setting.
        [switch] $ManualGroupMembership,

        # Sets the IIS application pool's process model `maxProcesses` setting.
        [UInt32] $MaxProcesses,

        # Sets the IIS application pool's process model `password` setting.
        [securestring] $Password,

        # Sets the IIS application pool's process model `pingingEnabled` setting.
        [switch] $PingingEnabled,

        # Sets the IIS application pool's process model `pingInterval` setting.
        [TimeSpan] $PingInterval,

        # Sets the IIS application pool's process model `pingResponseTime` setting.
        [TimeSpan] $PingResponseTime,

        # Sets the IIS application pool's process model `requestQueueDelegatorIdentity` setting.
        [String] $RequestQueueDelegatorIdentity,

        # Sets the IIS application pool's process model `setProfileEnvironment` setting.
        [switch] $SetProfileEnvironment,

        # Sets the IIS application pool's process model `shutdownTimeLimit` setting.
        [TimeSpan] $ShutdownTimeLimit,

        # Sets the IIS application pool's process model `startupTimeLimit` setting.
        [TimeSpan] $StartupTimeLimit,

        # Sets the IIS application pool's process model `userName` setting.
        [String] $UserName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $target = Get-CIisAppPool -Name $AppPoolName -Defaults:$AsDefaults
    if( -not $target )
    {
        return
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target.ProcessModel `
                                     -PSCmdlet $PSCmdlet `
                                     -Target """$($AppPoolName)"" IIS website's process model"
}
