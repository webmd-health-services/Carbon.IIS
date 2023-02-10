
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

    You can configure the IIS application pool defaults instead of a specific application pool by using the
    `AsDefaults` switch.

    If you want to ensure that any settings that may have gotten changed by hand are reset to their default values, use
    the `-Reset` switch. When set, the `-Reset` switch will reset each setting not passed as an argument to its default
    value.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/processmodel

    .EXAMPLE
    Set-CIisAppPoolProcessModel -AppPoolName 'ExampleTwo' -UserName 'user1' -Password $password

    Demonstrates how to set an IIS application pool to run as a custom identity. In this example, the application pool
    is updated to run as the user `user1`. All other process model settings are reset to their defaults.

    .EXAMPLE
    Set-CIisAppPoolProcessModel -AppPoolName 'ExampleOne' -UserName 'user1' -Password $password -Reset

    Demonstrates how to set *all* an IIS application pool's settings by using the `-Reset` switch. Any setting not passed
    as an argument is deleted, which resets it to its default value. In this example, the `ExampleOne` application
    pool's `userName` and `password` settings are updated and all other settings are deleted.

    .EXAMPLE
    Set-CIisAppPoolProcessModel -AsDefaults -IdleTimeout '00:00:00'

    Demonstrates how to configure the IIS application pool defaults process model settings by using the `AsDefaults`
    switch and not passing application pool name. In this example, the application pool defaults `idleTimeout` setting
    is set to `00:00:00`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the application pool whose process model settings to set.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $AppPoolName,

        # If true, the function configures the IIS application pool defaults instead of a specific application pool.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS application pool's process model `identityType` setting.
        [ProcessModelIdentityType] $IdentityType,

        # Sets the IIS application pool's process model `idleTimeout` setting.
        [TimeSpan] $IdleTimeout,

        # Sets the IIS application pool's process model `idleTimeoutAction` setting.
        [IdleTimeoutAction] $IdleTimeoutAction,

        # Sets the IIS application pool's process model `loadUserProfile` setting.
        [bool] $LoadUserProfile,

        # Sets the IIS application pool's process model `logEventOnProcessModel` setting.
        [ProcessModelLogEventOnProcessModel] $LogEventOnProcessModel,

        # Sets the IIS application pool's process model `logonType` setting.
        [CIisProcessModelLogonType] $LogonType,

        # Sets the IIS application pool's process model `manualGroupMembership` setting.
        [bool] $ManualGroupMembership,

        # Sets the IIS application pool's process model `maxProcesses` setting.
        [UInt32] $MaxProcesses,

        # Sets the IIS application pool's process model `password` setting.
        [securestring] $Password,

        # Sets the IIS application pool's process model `pingingEnabled` setting.
        [bool] $PingingEnabled,

        # Sets the IIS application pool's process model `pingInterval` setting.
        [TimeSpan] $PingInterval,

        # Sets the IIS application pool's process model `pingResponseTime` setting.
        [TimeSpan] $PingResponseTime,

        # Sets the IIS application pool's process model `requestQueueDelegatorIdentity` setting.
        [String] $RequestQueueDelegatorIdentity,

        # Sets the IIS application pool's process model `setProfileEnvironment` setting.
        [bool] $SetProfileEnvironment,

        # Sets the IIS application pool's process model `shutdownTimeLimit` setting.
        [TimeSpan] $ShutdownTimeLimit,

        # Sets the IIS application pool's process model `startupTimeLimit` setting.
        [TimeSpan] $StartupTimeLimit,

        # Sets the IIS application pool's process model `userName` setting.
        [String] $UserName,

        # If set, the application pool process model setting for each parameter *not* passed is deleted, which resets it
        # to its default value. Otherwise, application pool process model settings whose parameters are not passed are
        # left in place and not modified.
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

    $targetMsg = 'IIS application pool defaults process model'
    if( $AppPoolName )
    {
        $targetMsg = """$($AppPoolName)"" IIS application pool's process model"
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target.ProcessModel `
                                     -PSCmdlet $PSCmdlet `
                                     -Target $targetMsg `
                                     -Reset:$Reset `
                                     -Defaults (Get-CIIsAppPool -Defaults).ProcessModel
}
