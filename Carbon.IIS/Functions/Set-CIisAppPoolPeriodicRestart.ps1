
function Set-CIisAppPoolPeriodicRestart
{
    <#
    .SYNOPSIS
    Configures an IIS application pool's periodic restart settings.

    .DESCRIPTION
    The `Set-CIisAppPoolPeriodicRestart` function configures all the settings on an IIS application pool's
    periodic restart settings. Pass the name of the application pool to the `AppPoolName` parameter. Pass the
    configuration to the `Memory`, `PrivateMemory`, `Requests`, and `Time` parameters (see
    [Periodic Restart Settings for Application Pool Recycling <periodicRestart>](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/recycling/periodicrestart/))
    for documentation on what these settings are for.

    Use the `Schedule` parameter to add times to the periodic restart configuration for time each day IIS should recycle
    the application pool.

    If you want to ensure that any settings that may have gotten changed by hand are reset to their default values, use
    the `-Reset` switch. When set, the `-Reset` switch will reset each setting not passed as an argument to its default
    value.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/applicationpools/add/recycling/periodicrestart/

    .EXAMPLE
    Set-CIisAppPoolPeriodicRestart -AppPoolName 'Snafu' -Memory 1000000 -PrivateMemory 2000000 -Requests 3000000 -Time '23:00:00'

    Demonstrates how to configure all an IIS applicaton pool's periodic restart settings. In this example, `memory` will
    be set to `1000000`, `privateMemory` will be set to `2000000`, `requests` will be sent to `3000000`, and `time` will
    be sent to `23:00:00'.

    .EXAMPLE
    Set-CIisAppPoolPeriodicRestart -AppPoolName 'Fubar' -Memory 1000000 -PrivateMemory 2000000 -Reset

    Demonstrates how to set *all* an IIS application pool's periodic restart settings by using the `-Reset` switch. Any
    setting not passed will be deleted, which resets it to its default value. In this example, the `memory` and
    `privateMemory` settings are configured, and all other settings are set to their default values.

    .EXAMPLE
    Set-CIisAppPoolPeriodicRestart -AsDefaults -Memory 1000000 -PrivateMemory 2000000

    Demonstrates how to configure the IIS application pool defaults periodic restart settings by using the `AsDefaults`
    switch and not passing the application pool name.
    #>
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the IIS application pool whose periodic restart settings to configure.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $AppPoolName,

        # If true, the function configures IIS' application pool defaults instead of
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS application pool's periodic restart `memory` setting.
        [UInt32] $Memory,

        # Sets the IIS application pool's periodic restart `privateMemory` setting.
        [UInt32] $PrivateMemory,

        # Sets the IIS application pool's periodic restart `requests` setting.
        [UInt32] $Requests,

        # Sets the IIS application pool's periodic restart `time` setting.
        [TimeSpan] $Time,

        # Sets the IIS application pool's periodic restart `schedule` list. The default is to have no scheduled
        # restarts.
        [TimeSpan[]] $Schedule = @(),

        # If set, the application pool periodic restart setting for each parameter *not* passed is deleted, which resets
        # it to its default value. Otherwise, application pool periodic restart settings whose parameters are not passed
        # are left in place and not modified.
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

    $appPool = Get-CIisAppPool @getArgs
    if( -not $appPool )
    {
        return
    }

    $currentSchedule = $appPool.Recycling.PeriodicRestart.Schedule
    $currentTimes = $currentSchedule | Select-Object -ExpandProperty 'Time' | Sort-Object
    $Schedule = $Schedule | Sort-Object
    $scheduleChanged = $false
    if( ($currentTimes -join ', ') -ne ($Schedule -join ', ') )
    {
        $prefixMsg = "IIS ""$($AppPoolName)"" application pool: periodic restart schedule  "
        $clearedPrefix = $false

        foreach( $time in (($currentTimes + $Schedule) | Select-Object -Unique) )
        {
            $icon = ' '
            $action = ''
            if( $Schedule -notcontains $time )
            {
                $icon = '-'
                $action = 'Remove'
            }
            elseif( $currentTimes -notcontains $time )
            {
                $icon = '+'
                $action = 'Add'
            }

            if( $icon -eq ' ' )
            {
                continue
            }

            $action = "$($action) Time"
            $target = "$($time) for '$($AppPoolName)' IIS application pool's periodic restart schedule"
            if( $PSCmdlet.ShouldProcess($target, $action) )
            {
                Write-Information "$($prefixMsg)$($icon) $($time)"
                $scheduleChanged = $true
            }
            if( -not $clearedPrefix )
            {
                $prefixMsg = ' ' * $prefixMsg.Length
                $clearedPrefix = $true
            }
        }

        if ($scheduleChanged)
        {
            $currentSchedule.Clear()
            foreach( $time in $Schedule )
            {
                $add = $currentSchedule.CreateElement('add')
                try
                {
                    $add.SetAttributeValue('value', $time)
                }
                catch
                {
                    $msg = "Failed to add time ""$($time)"" to ""$($AppPoolName)"" IIS application pool's periodic " +
                        "restart schedule: $($_)"
                    Write-Error -Message $msg -ErrorAction Stop
                }

                $currentSchedule.Add($add)
            }

            Save-CIisConfiguration
        }
    }

    $appPool = Get-CIisAppPool @getArgs
    if( -not $appPool )
    {
        return
    }

    $targetMsg = 'IIS appliation pool defaults periodic restart'
    if( $AppPoolName )
    {
        $targetMsg = """$($AppPoolName)"" IIS application pool's periodic restart"
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $appPool.Recycling.PeriodicRestart `
                                     -PSCmdlet $PSCmdlet `
                                     -Target $targetMsg `
                                     -Reset:$Reset `
                                     -Defaults (Get-CIIsAppPool -Defaults).Recycling.PeriodicRestart `
                                     -AsDefaults:$AsDefaults
}
