
function Install-CIisAppPool
{
    <#
    .SYNOPSIS
    Creates a new app pool.

    .DESCRIPTION
    By default, creates a 64-bit app pool running as the `ApplicationPoolIdentity` service account under .NET v4.0 with
    an integrated pipeline.

    You can control which version of .NET is used to run an app pool with the `ManagedRuntimeVersion` parameter:
    versions `v1.0`, `v1.1`, `v2.0`, and `v4.0` are supported. Use an empty string if you're running .NET Core or to set
    the .NET framework version to `No Managed Code`.

    To run an application pool using the classic pipeline mode, set the `ClassicPipelineMode` switch.

    To run an app pool using the 32-bit version of the .NET framework, set the `Enable32BitApps` switch.

    An app pool can run as several built-in service accounts, by passing one of them as the value of the
    `ServiceAccount` parameter: `NetworkService`, `LocalService`, or `LocalSystem`. If no service account or identity is
    provided, `Install-CIisAppPool` sets the app pool to run as `ApplicationPoolIdentity`, a principal that IIS creates
    and manages. See [Application Pool Identities](http://learn.iis.net/page.aspx/624/application-pool-identities/) for
    more information on these types of accounts.

    To run the app pool as a specific user, pass the credentials with the `Credential` parameter. The user will be
    granted the `SeBatchLogonRight` privilege.

    If an existing app pool exists with name `Name`, it's settings are modified.  The app pool isn't deleted.  (You
    can't delete an app pool if there are any websites using it, that's why.)

    To configure the application pool's periodic restart settings, use the `Set-CIisAppPoolPeriodicRestart`
    can't delete an app pool if there are any websites using it, that's why.)

    By default, this function will create an application pool running the latest version of .NET, with an integrated
    pipeline, as the `ApplicationPoolIdentity` account.

    .LINK
    http://learn.iis.net/page.aspx/624/application-pool-identities/

    .LINK
    New-CCredential

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -ServiceAccount NetworkService

    Creates a new Cyberdyne application pool, running as NetworkService, using .NET 4.0 and an integrated pipeline.  If
    the Cyberdyne app pool already exists, it is modified to run as NetworkService, to use .NET 4.0 and to use an
    integrated pipeline.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -ServiceAccount NetworkService -Enable32BitApps -ClassicPipelineMode

    Creates or sets the Cyberdyne app pool to run as NetworkService, in 32-bit mode (i.e. 32-bit applications are
    enabled), using the classic IIS request pipeline.

    .EXAMPLE
    Install-CIisAppPool -Name Cyberdyne -Credential $charlieBrownCredential

    Creates or sets the Cyberdyne app pool to run as the `PEANUTS\charliebrown` domain account, under .NET 4.0, with an
    integrated pipeline.
    #>
    [CmdletBinding(DefaultParameterSetName='AsServiceAccount')]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        # The app pool's name.
        [Parameter(Mandatory)]
        [String] $Name,

        # The managed .NET runtime version to use.  Default is 'v4.0'.  Valid values are `v1.0`, `v1.1`, `v2.0`, or
        #$ `v4.0`. Use an empty string if you're using .NET Core or to set the .NET framework version to
        # `No Managed Code`.
        [ValidateSet('v1.0','v1.1','v2.0','v4.0','')]
        [String] $ManagedRuntimeVersion = 'v4.0',

        # Idle Timeout value in minutes. Default is 0.
        [ValidateScript({$_ -gt 0})]
        [int] $IdleTimeout = 0,

        # Use the classic pipeline mode, i.e. don't use an integrated pipeline.
        [switch] $ClassicPipelineMode,

        # Enable 32-bit applications.
        [switch] $Enable32BitApps,

        # Run the app pool under the given local service account.  Valid values are `NetworkService`, `LocalService`,
        # and `LocalSystem`. If no `ServiceAccount` or `Credential` arguments are provided, the app pool will be set to
        # run as an `ApplicationPoolIdentity`, a principal that IIS creates and manages.
        [ValidateSet('NetworkService', 'LocalService', 'LocalSystem')]
        [String] $ServiceAccount,

        # The credential to use to run the app pool. If no `ServiceAccount` or `Credential` arguments are provided, the
        # app pool will be set to run as an `ApplicationPoolIdentity`, a principal that IIS creates and manages.
        [Parameter(Mandatory, ParameterSetName='AsSpecificUserWithCredential')]
        [pscredential] $Credential,

        # Return an object representing the app pool.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'AsSpecificUser' -and -not (Test-CIdentity -Name $Credential.UserName) )
    {
        Write-Error ('Identity {0} not found. {0} IIS websites and applications assigned to this app pool won''t run.' -f $Credential.UserName,$Name)
    }

    if( -not (Test-CIisAppPool -Name $Name) )
    {
        Write-Verbose ('Creating IIS Application Pool {0}' -f $Name)
        $mgr = Get-CIisServerManager
        $appPool = $mgr.ApplicationPools.Add($Name)
        Save-CIisConfiguration
    }

    $appPool = Get-CIisAppPool -Name $Name

    $updated = $false

    if( $appPool.ManagedRuntimeVersion -ne $ManagedRuntimeVersion )
    {
        Write-Verbose ('IIS Application Pool {0}: Setting ManagedRuntimeVersion = {0}' -f $Name,$ManagedRuntimeVersion)
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
        Write-Verbose ('IIS Application Pool {0}: Setting ManagedPipelineMode = {0}' -f $Name,$pipelineMode)
        $appPool.ManagedPipelineMode = $pipelineMode
        $updated = $true
    }

    $idleTimeoutTimeSpan = New-TimeSpan -Minutes $IdleTimeout
    if( $appPool.ProcessModel.IdleTimeout -ne $idleTimeoutTimeSpan )
    {
        Write-Verbose ('IIS Application Pool {0}: Setting idle timeout = {0}' -f $Name,$idleTimeoutTimeSpan)
        $appPool.ProcessModel.IdleTimeout = $idleTimeoutTimeSpan
        $updated = $true
    }

    if( $appPool.Enable32BitAppOnWin64 -ne ([bool]$Enable32BitApps) )
    {
        Write-Verbose ('IIS Application Pool {0}: Setting Enable32BitAppOnWin64 = {0}' -f $Name,$Enable32BitApps)
        $appPool.Enable32BitAppOnWin64 = $Enable32BitApps
        $updated = $true
    }

    if( $PSCmdlet.ParameterSetName -like 'AsSpecificUser*' )
    {
        if( $appPool.ProcessModel.UserName -ne $Credential.UserName )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting username = {0}' -f $Name,$Credential.UserName)
            $appPool.ProcessModel.IdentityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::SpecificUser
            $appPool.ProcessModel.UserName = $Credential.UserName
            $appPool.ProcessModel.Password = $Credential.GetNetworkCredential().Password

            # On Windows Server 2008 R2, custom app pool users need this privilege.
            Grant-CPrivilege -Identity $Credential.UserName -Privilege SeBatchLogonRight -Verbose:$VerbosePreference
            $updated = $true
        }
    }
    else
    {
        $identityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::ApplicationPoolIdentity
        if( $ServiceAccount )
        {
            $identityType = $ServiceAccount
        }

        if( $appPool.ProcessModel.IdentityType -ne $identityType )
        {
            Write-Verbose ('IIS Application Pool {0}: Setting IdentityType = {0}' -f $Name,$identityType)
            $appPool.ProcessModel.IdentityType = $identityType
            $updated = $true
        }
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

