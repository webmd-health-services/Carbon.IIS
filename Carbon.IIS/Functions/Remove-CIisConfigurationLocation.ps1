
function Remove-CIisConfigurationLocation
{
    <#
    .SYNOPSIS
    Removes a <location> element from applicationHost.config.

    .DESCRIPTION
    The `Remove-CIisConfigurationLocation` function removes the entire location configuration for a website or a path
    under a website. When configuration for a website or path under a website is made, those changes are sometimes
    persisted to IIS's applicationHost.config file. The configuration is placed inside a `<location>` element for that
    site and path. This function removes the entire `<location>` section, i.e. all a site's/path's custom configuration
    that isn't stored in a web.config file.

    Pass the website whose location configuration to remove to the `SiteName` parameter. To delete the location
    configuration for a path under the website, pass that path to the `VirtualPath` parameter.

    If there is no location configuration, an error is written.

    .EXAMPLE
    Remove-CIisConfigurationLocation -SiteName 'www'

    Demonstrates how to remove the `<location path="www">` element from IIS's applicationHost.config, i.e. all custom
    configuration for the www website that isn't in the site's web.config file.

    .EXAMPLE
    Remove-CIisConfigurationLocation -SiteName 'www' -VirtualPath 'some/path'

    Demonstrates how to remove the `<location path="www/some/path">` element from IIS's applicationHost.config, i.e.
    all custom configuration for the `some/path` path in the `www` website that isn't in the path's or site's web.config
    file.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [String] $SiteName,

        [String] $VirtualPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $locationPath = Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath

    if( -not (Get-CIisConfigurationLocationPath -SiteName $SiteName -VirtualPath $VirtualPath) )
    {
        $msg = "Configuration location ""$($locationPath)"" does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    (Get-CIisServerManager).GetApplicationHostConfiguration().RemoveLocationPath($locationPath)
    $target = "$($locationPath)"
    $action = "Remove IIS Location"
    $infoMsg = "Removing ""$($locationPath)"" IIS location configuration."
    Save-CIisConfiguration -Target $target -Action $action -Message $infoMsg
}