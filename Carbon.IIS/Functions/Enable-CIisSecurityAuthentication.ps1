
function Enable-CIisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Enables anonymous, basic, or Windows authentication for an entire site or a sub-directory of that site.

    .DESCRIPTION
    The `Enable-CIisSecurityAuthentication` function enables anonymous, basic, or Windows authentication for a website,
    application, virtual directory, or directory. Pass the location's path to the `LocationPath` parameter. Use the
    `Anonymous` switch to enable anonymous authentication, the `Basic` switch to enable basic authentication, or the
    `Windows` switch to enable Windows authentication.

    .LINK
    Disable-CIisSecurityAuthentication

    .LINK
    Get-CIisSecurityAuthentication

    .LINK
    Test-CIisSecurityAuthentication

    .EXAMPLE
    Enable-CIisSecurityAuthentication -LocationPath 'Peanuts' -Anonymous

    Turns on anonymous authentication for the `Peanuts` website.

    .EXAMPLE
    Enable-CIisSecurityAuthentication -LocationPath 'Peanuts/Snoopy/DogHouse' -Basic

    Turns on anonymous authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The location path to the website, application, virtual directory, or directory where the authentication
        # method should be enabled.
        [Parameter(Mandatory)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

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
    Set-CIisConfigurationAttribute -LocationPath $LocationPath `
                                   -VirtualPath $VirtualPath `
                                   -SectionPath $sectionPath `
                                   -Name 'enabled' `
                                   -Value $true
}
