
function Set-CIisWebsiteLogFile
{
    <#
    .SYNOPSIS
    Configures an IIS website's log file settings.

    .DESCRIPTION
    The `Set-CIisWebsiteLogFile` function configures an IIS website's log files settings. Pass the name of the
    website to the `SiteName` parameter. Pass the log files configuration you want to the `CustomLogPluginClsid`,
    `Directory`, `Enabled`, `FlushByEntryCountW3CLog`, `LocalTimeRollover`, `LogExtFileFlags`, `LogFormat`, `LogSiteID`,
    `LogTargetW3C`, `MaxLogLineLength`, `Period`, and `TruncateSize` parameters (see
    [Log Files for a Web Site <logFile>](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/logfile/))
    for documentation on what these settings are for.

    If any parameters are not passed, those settings will be reset to their default values.

    .LINK
    https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/logfile/

    .EXAMPLE
    Set-CIisWebsiteLogFile -AppPoolName 'Fubar'

    Demonstrates how to reset an IIS website's log file settings to their default values by not passing any arguments.

    .EXAMPLE
    Set-CIisWebsiteLogFile -AppPoolName 'Snafu' -Directory 'C:\logs' -MaxLogLineLength 32768

    Demonstrates how to configure an IIS website's log file settings. In this example, `directory` will be set to
    `C:\logs` and `maxLogLineLength` will be set to `32768`. All other settings will be reset to their default values.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the website whose log file settings to set.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $SiteName,

        # If true, the function configures IIS's application pool defaults instead of a specific application pool.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        # Sets the IIS website's log files `customLogPluginClsid` setting.
        [String] $CustomLogPluginClsid,

        # Sets the IIS website's log files `directory` setting.
        [String] $Directory,

        # Sets the IIS website's log files `enabled` setting.
        [bool] $Enabled,

        # Sets the IIS website's log files `flushByEntryCountW3CLog` setting.
        [UInt32] $FlushByEntryCountW3CLog,

        # Sets the IIS website's log files `localTimeRollover` setting.
        [bool] $LocalTimeRollover,

        # Sets the IIS website's log files `logExtFileFlags` setting.
        [LogExtFileFlags] $LogExtFileFlags,

        # Sets the IIS website's log files `logFormat` setting.
        [LogFormat] $LogFormat,

        # Sets the IIS website's log files `logSiteID` setting.
        [bool] $LogSiteID,

        # Sets the IIS website's log files `logTargetW3C` setting.
        [LogTargetW3C] $LogTargetW3C,

        # Sets the IIS website's log files `maxLogLineLength` setting.
        [UInt32] $MaxLogLineLength,

        # Sets the IIS website's log files `period` setting.
        [LoggingRolloverPeriod] $Period,

        # Sets the IIS website's log files `truncateSize` setting.
        [Int64] $TruncateSize
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $SiteName -Defaults:$AsDefaults
    if( -not $site )
    {
        return
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $site.LogFile `
                                     -PSCmdlet $PSCmdlet `
                                     -Target """$($SiteName)"" IIS website's log file"
}
