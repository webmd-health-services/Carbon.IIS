
function Disable-CIisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Disables anonymous, basic, or Windows authentication for all or part of a website.

    .DESCRIPTION
    By default, disables an authentication type for an entire website.  You can disable an authentication type at a
    specific path under a website by passing the virtual path (*not* the physical path) to that directory as the value
    of the `VirtualPath` parameter.

    .LINK
    Enable-CIisSecurityAuthentication

    .LINK
    Get-CIisSecurityAuthentication

    .LINK
    Test-CIisSecurityAuthentication

    .EXAMPLE
    Disable-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

    Turns off anonymous authentication for the `Peanuts` website.

    .EXAMPLE
    Disable-CIisSecurityAuthentication -SiteName Peanuts Snoopy/DogHouse -Basic

    Turns off basic authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The site where authentication should be disabled.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The optional path where authentication should be disabled.
        [String] $VirtualPath = '',

        # Disable anonymous authentication.
        [Parameter(Mandatory, ParameterSetName='anonymousAuthentication')]
        [switch] $Anonymous,

        # Disable basic authentication.
        [Parameter(Mandatory, ParameterSetName='basicAuthentication')]
        [switch] $Basic,

        # Disable Windows authentication.
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
                                   -Value $false
}
