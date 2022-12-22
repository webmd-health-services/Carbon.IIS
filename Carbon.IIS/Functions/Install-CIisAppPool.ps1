
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
    [CmdletBinding(DefaultParameterSetName='New')]
    param(
        # The app pool's name.
        [Parameter(Mandatory)]
        [String] $Name,

        # Sets the IIS application pool's `autoStart` setting.
        [Parameter(ParameterSetName='New')]
        [bool] $AutoStart,

        # Sets the IIS application pool's `CLRConfigFile` setting.
        [Parameter(ParameterSetName='New')]
        [String] $CLRConfigFile,

        # Sets the IIS application pool's `enable32BitAppOnWin64` setting.
        [Parameter(ParameterSetName='New')]
        [bool] $Enable32BitAppOnWin64,

        # Sets the IIS application pool's `enableConfigurationOverride` setting.
        [Parameter(ParameterSetName='New')]
        [bool] $EnableConfigurationOverride,

        # Sets the IIS application pool's `managedPipelineMode` setting.
        [ManagedPipelineMode] $ManagedPipelineMode,

        # Sets the IIS application pool's `managedRuntimeLoader` setting.
        [Parameter(ParameterSetName='New')]
        [String] $ManagedRuntimeLoader,

        # Sets the IIS application pool's `managedRuntimeVersion` setting.
        [String] $ManagedRuntimeVersion,

        # Sets the IIS application pool's `passAnonymousToken` setting.
        [Parameter(ParameterSetName='New')]
        [bool] $PassAnonymousToken,

        # Sets the IIS application pool's `queueLength` setting.
        [Parameter(ParameterSetName='New')]
        [UInt32] $QueueLength,

        # Sets the IIS application pool's `startMode` setting.
        [Parameter(ParameterSetName='New')]
        [StartMode] $StartMode,

        # Return an object representing the app pool.
        [switch] $PassThru,

        #Idle Timeout value in minutes. Default is 0.
        [Parameter(ParameterSetName='Deprecated')]
        [ValidateScript({$_ -gt 0})]
        [int] $IdleTimeout = 0,

        # Run the app pool under the given local service account.  Valid values are `NetworkService`, `LocalService`,
        # and `LocalSystem`.  The default is `ApplicationPoolIdentity`, which causes IIS to create a custom local user
        # account for the app pool's identity.  The default is `ApplicationPoolIdentity`.
        [Parameter(ParameterSetName='Deprecated')]
        [ValidateSet('NetworkService', 'LocalService', 'LocalSystem')]
        [String] $ServiceAccount,

        # The credential to use to run the app pool.
        #
        # The `Credential` parameter is new in Carbon 2.0.
        [Parameter(ParameterSetName='Deprecated', Mandatory)]
        [pscredential] $Credential,

        # Enable 32-bit applications.
        [Parameter(ParameterSetName='Deprecated')]
        [switch] $Enable32BitApps,

        # Use the classic pipeline mode, i.e. don't use an integrated pipeline.
        [Parameter(ParameterSetName='Deprecated')]
        [switch] $ClassicPipelineMode
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -eq 'Deprecated')
    {
        $functionName = $PSCmdlet.MyInvocation.MyCommand.Name

        $installArgs = @{
            'ManagedPipelineMode' = [ManagedPipelineMode]::Integrated
            'ManagedRuntimeVersion' = 'v4.0'
        }

        $installArgs['Enable32BitAppOnWin64'] = $Enable32BitApps.IsPresent

        if ($ClassicPipelineMode)
        {
            "The ""$($functionName)"" function's ""ClassicPipelineMode"" switch is deprecated. Use the " +
            '"ManagedPipelineMode" parameter instead.' | Write-CIIsWarningOnce

            $installArgs['ManagedPipelineMode'] = [ManagedPipelineMode]::Classic
        }

        if ($ManagedRuntimeVersion)
        {
            $installArgs['ManagedRuntimeVersion'] = $ManagedRuntimeVersion
        }

        if ($PassThru)
        {
            $installArgs['PassThru'] = $PassThru
        }

        Install-CIisAppPool -Name $Name @installArgs

        $setProcessModelArgs = @{}

        if ($Credential)
        {
            "The ""$($functionName)"" function's ""Credential"" parameter is deprecated. Use the " +
            '"Set-CIisAppPoolProcessModel" function and its "IdentityType", "UserName", and "Password" parameters ' +
            'instead.' | Write-CIIsWarningOnce

            $setProcessModelArgs['IdentityType'] = [ProcessModelIdentityType]::SpecificUser
            $setProcessModelArgs['UserName'] = $Credential.UserName
            $setProcessModelArgs['Password'] = $Credential.Password
        }
        elseif ($ServiceAccount)
        {
            "The $($functionName) function's ""ServiceAccount"" parameter is deprecated. Use the " +
            '"Set-CIisAppPoolProcessModel" function and its "IdentityType" parameter instead.' | Write-CIIsWarningOnce

            $setProcessModelArgs['IdentityType'] = $ServiceAccount
        }

        if ($IdleTimeout)
        {
            "The $($functionName) function's ""IdleTimeout"" parameter is deprecated. Use the " +
            '"Set-CIisAppPoolProcessModel" function and its "IdleTimeout" parameter instead.' | Write-CIIsWarningOnce
            $setProcessModelArgs['IdleTimeout'] = $IdleTimeout
        }

        if ($setProcessModelArgs.Count -eq 0)
        {
            return
        }

        Set-CIisAppPoolProcessModel -AppPoolName $Name @setProcessModelArgs
        return
    }

    if( -not (Test-CIisAppPool -Name $Name) )
    {
        Write-Information "Creating IIS Application Pool ""$($Name)""."
        $mgr = Get-CIisServerManager
        $mgr.ApplicationPools.Add($Name) | Out-Null
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

    Start-CIisAppPool -Name $Name

    if( $PassThru )
    {
        return (Get-CIisAppPool -Name $Name)
    }
}

