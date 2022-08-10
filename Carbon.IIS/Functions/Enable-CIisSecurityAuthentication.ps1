
function Enable-CIisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Enables anonymous, basic, or Windows authentication for an entire site or a sub-directory of that site.

    .DESCRIPTION
    By default, enables an authentication type on an entire website.  You can enable an authentication type at a
    specific path under a website by passing the virtual path (*not* the physical path) to that directory as the value
    of the `VirtualPath` parameter.

    .LINK
    Disable-CIisSecurityAuthentication

    .LINK
    Get-CIisSecurityAuthentication

    .LINK
    Test-CIisSecurityAuthentication

    .EXAMPLE
    Enable-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

    Turns on anonymous authentication for the `Peanuts` website.

    .EXAMPLE
    Enable-CIisSecurityAuthentication -SiteName Peanuts Snoopy/DogHouse -Basic

    Turns on anonymous authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The site where authentication should be set.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The optional path where authentication should be set.
        [Alias('Path')]
        [String] $VirtualPath = '',

        # Enable anonymous authentication.
        [Parameter(Mandatory, ParameterSetName='anonymousAuthentication')]
        [switch] $Anonymous,

        # Enable basic authentication.
        [Parameter(Mandatory, ParameterSetName='basicAuthentication')]
        [switch] $Basic,

        # Enable Windows authentication.
        [Parameter(Mandatory, ParameterSetName='windowsAuthentication')]
        [switch] $Windows
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sectionPath = "system.webServer/security/authentication/$($PSCmdlet.ParameterSetName)"
    Set-CIisConfigurationAttribute -SiteName $SiteName `
                                   -VirtualPath $VirtualPath `
                                   -SectionPath $sectionPath `
                                   -Name 'enabled' `
                                   -Value $true
}
