
function Install-CIisAppPool
{
    <#
    .SYNOPSIS
    Creates or updates an IIS application pool.

    .DESCRIPTION
    The `Install-CIisAppPool` function creates or updates an IIS application pool. Pass the name of the application pool
    to the `Name` parameter. If that application pool doesn't exist, it is created. If it does exist, its configuration
    is updated to match the values of the arguments passed. If you don't pass an argument, that argument's setting is
    deleted and reset to its default value. You always get an application pool with the exact same configuration, even
    if someone or something has changed an application pool's configuration in some other way.

    To configure the application pool's process model (i.e. the application pool's account/identity, idle timeout,
    etc.), use the `Set-CIisAppPoolProcessModel` function.

    To configure the application pool's periodic restart settings, use the `Set-CIisAppPoolPeriodicRestart`
    function.

    To configure the application pool's periodic restart settings, use the `Set-CIisAppPoolPeriodicRestart`
    can't delete an app pool if there are any websites using it, that's why.)

    To configure the application pool's CPU settings, use the `Set-CIisAppPoolCpu` function.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne

    Demonstrates how to use Install-CIisAppPool to create/update an application pool with reasonable defaults. In this
    example, an application pool named "Cyberdyne" is created that is 64-bit, uses .NET 4.0, and an integrated pipeline.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -Enable32BitAppOnWin64 $true -ManagedPipelineMode Classic -ManagedRuntimeVersion 'v2.0'

    Demonstrates how to customize an application pool away from its default settings. In this example, the "Cyberdyne"
    application pool is created that is 32-bit, uses .NET 2.0, and a classic pipeline.
    #>
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        # The app pool's name.
        [Parameter(Mandatory)]
        [String] $Name,

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

        # Return an object representing the app pool.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CIisAppPool -Name $Name) )
    {
        Write-Information "Creating IIS Application Pool ""$($Name)""."
        $mgr = Get-CIisServerManager
        $appPool = $mgr.ApplicationPools.Add($Name)
        Save-CIisConfiguration
    }

    $setArgs = @{}
    foreach( $parameterName in (Get-Command -Name 'Set-CIisAppPool').Parameters.Keys )
    {
        if( -not $PSBoundParameters.ContainsKey($parameterName) )
        {
            continue
        }
        $setArgs[$parameterName] = $PSBoundParameters[$parameterName]
    }
    Set-CIisAppPool @setArgs -Reset

    # TODO: Pull this out into its own Start-IisAppPool function. I think.
    $appPool = Get-CIisAppPool -Name $Name
    if($appPool -and $appPool.state -eq [Microsoft.Web.Administration.ObjectState]::Stopped )
    {
        try
        {
            $appPool.Start()
        }
        catch
        {
            Write-Error ('Failed to start {0} app pool: {1}' -f $Name,$_.Exception.Message)
        }
    }

    if( $PassThru )
    {
        $appPool
    }
}

