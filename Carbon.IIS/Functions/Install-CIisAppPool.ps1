
function Install-CIisAppPool
{
    <#
    .SYNOPSIS
    Creates or updates an IIS application pool.

    .DESCRIPTION
    The `Install-CIisAppPool` function creates or updates an IIS application pool. Pass the name of the application pool
    to the `Name` parameter. If that application pool doesn't exist, it is created. If it does exist, its configuration
    is updated to match the values of the arguments passed.

    If you pass just a name, the function creates a 64-bit application pool that runs an integrated pipeline using the
    .NET 4.0 managed runtime. To use a 32-bit app pool, use the `Enable32BitApps` switch. To use a classic pipeline,
    use the `ClassicPipelineMode` switch. To use a different version of .NET, use the `ManagedRuntimeVersion`
    parameter.

    To configure the application pool's process model (i.e. the application pool's account/identity, idle timeout, etc.,
    use the `Set-CIisAppPoolProcessModel`)

    To configure the application pool's periodic restart settings, use the `Set-CIisAppPoolRecyclingPeriodicRestart`
    function.

    To configure the application pool's CPU settings, use the `Set-CIisAppPoolCpu` function.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne

    Demonstrates how to use Install-CIisAppPool to create/update an application pool with reasonable defaults. In this
    example, an application pool named "Cyberdyne" is created that is 64-bit, uses .NET 4.0, and an integrated pipeline.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -Enable32BitApps -ClassicPipelineMode -ManagedRuntime 'v2.0'

    Demonstrates how to customize an application pool away from its default settings. In this example, the "Cyberdyne"
    application pool is created that is 32-bit, uses .NET 2.0, and a classic pipeline.
    #>
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        # The app pool's name.
        [Parameter(Mandatory)]
        [String] $Name,

        # The managed .NET runtime version to use.  Default is 'v4.0'.  Valid values are `v1.0`, `v1.1`, `v2.0`, or
        #$ `v4.0`. Use an empty string if you're using .NET Core or to set the .NET framework version to
        # `No Managed Code`.
        [ValidateSet('v1.0','v1.1','v2.0','v4.0','')]
        [String] $ManagedRuntimeVersion = 'v4.0',

        # Use the classic pipeline mode, i.e. don't use an integrated pipeline.
        [switch] $ClassicPipelineMode,

        # Enable 32-bit applications.
        [switch] $Enable32BitApps,

        # Return an object representing the app pool.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function Add-InfoMessage
    {
        param(
            [Parameter(Mandatory)]
            [String] $PropertyName,

            [Parameter(Mandatory)]
            [AllowNull()]
            [AllowEmptyString()]
            [String] $CurrentValue,

            [Parameter(Mandatory)]
            [AllowNull()]
            [AllowEmptyString()]
            [String] $NewValue
        )

        $infos.Add("    $('{0,15}' -f $PropertyName)  $($CurrentValue) -> $($NewValue)")
    }

    $action = 'Updating'
    if( -not (Test-CIisAppPool -Name $Name) )
    {
        $action = 'Creating' # IIS Application Pool ""$($Name)""."
        $mgr = Get-CIisServerManager
        $appPool = $mgr.ApplicationPools.Add($Name)
        Save-CIisConfiguration
    }

    $appPool = Get-CIisAppPool -Name $Name

    $updated = $false

    $infos = [Collections.Generic.List[String]]::New()
    if( $appPool.ManagedRuntimeVersion -ne $ManagedRuntimeVersion )
    {
        Add-InfoMessage -PropertyName 'managedRuntimeVersion' `
                        -CurrentValue $appPool.ManagedRuntimeVersion `
                        -NewValue $ManagedRuntimeVersion
        $appPool.ManagedRuntimeVersion = $ManagedRuntimeVersion
        $updated = $true
    }

    $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Integrated
    if( $ClassicPipelineMode )
    {
        $pipelineMode = [Microsoft.Web.Administration.ManagedPipelineMode]::Classic
    }

    if( $appPool.ManagedPipelineMode -ne $pipelineMode )
    {
        Add-InfoMessage -PropertyName 'managedPipelineMode' `
                        -CurrentValue $appPool.ManagedPipelineMode `
                        -NewValue $pipelineMode
        $appPool.ManagedPipelineMode = $pipelineMode
        $updated = $true
    }

    if( $appPool.Enable32BitAppOnWin64 -ne ([bool]$Enable32BitApps) )
    {
        Add-InfoMessage -PropertyName 'enable32BitAppOnWin64' `
                        -CurrentValue $appPool.Enable32BitAppOnWin64 `
                        -NewValue $Enable32BitApps
        $appPool.Enable32BitAppOnWin64 = $Enable32BitApps
        $updated = $true
    }

    if( $updated -or $action -eq 'Creating')
    {
        Write-Information "$($action) IIS application pool ""$($Name)""."
        $infos | ForEach-Object { Write-Information $_ }
    }

    if( $updated )
    {
        Save-CIisConfiguration
    }

    # TODO: Pull this out into its own Start-IisAppPool function.  I think.
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

