
function Get-CIisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Gets a site's (and optional sub-directory's) security authentication configuration section.

    .DESCRIPTION
    You can get the anonymous, basic, digest, and Windows authentication sections by using the `Anonymous`, `Basic`,
    `Digest`, or `Windows` switches, respectively.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    Microsoft.Web.Administration.ConfigurationSection.

    .EXAMPLE
    Get-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

    Gets the `Peanuts` site's anonymous authentication configuration section.

    .EXAMPLE
    Get-CIisSecurityAuthentication -SiteName Peanuts -VirtualPath Doghouse -Basic

    Gets the `Peanuts` site's `Doghouse` sub-directory's basic authentication configuration section.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        # The site where anonymous authentication should be set.
        [Parameter(Mandatory, Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

        # Gets a site's (and optional sub-directory's) anonymous authentication configuration section.
        [Parameter(Mandatory, ParameterSetName='anonymousAuthentication')]
        [switch] $Anonymous,

        # Gets a site's (and optional sub-directory's) basic authentication configuration section.
        [Parameter(Mandatory, ParameterSetName='basicAuthentication')]
        [switch] $Basic,

        # Gets a site's (and optional sub-directory's) digest authentication configuration section.
        [Parameter(Mandatory, ParameterSetName='digestAuthentication')]
        [switch] $Digest,

        # Gets a site's (and optional sub-directory's) Windows authentication configuration section.
        [Parameter(Mandatory, ParameterSetName='windowsAuthentication')]
        [switch] $Windows
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sectionPath = 'system.webServer/security/authentication/{0}' -f $PSCmdlet.ParameterSetName
    Get-CIisConfigurationSection -LocationPath $locationPath -VirtualPath $VirtualPath -SectionPath $sectionPath
}
