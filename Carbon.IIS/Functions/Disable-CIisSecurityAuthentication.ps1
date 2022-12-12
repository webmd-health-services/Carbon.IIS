
function Disable-CIisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Disables anonymous, basic, or Windows authentication for all or part of a website.

    .DESCRIPTION
    The `Disable-CIisSecurityAuthentication` function disables anonymous, basic, or Windows authentication for a
    website, application, virtual directory, or directory. Pass the path to the `LocationPath` parameter. Use the
    `Anonymous` switch to disable anonymous authentication, the `Basic` switch to disable basic authentication, or the
    `Windows` switch to disable Windows authentication.

    .LINK
    Enable-CIisSecurityAuthentication

    .LINK
    Get-CIisSecurityAuthentication

    .LINK
    Test-CIisSecurityAuthentication

    .EXAMPLE
    Disable-CIisSecurityAuthentication -LocationPath 'Peanuts' -Anonymous

    Turns off anonymous authentication for the `Peanuts` website.

    .EXAMPLE
    Disable-CIisSecurityAuthentication -LocationPath 'Peanuts/Snoopy/DogHouse' -Basic

    Turns off basic authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The location path to the website, directory, application, or virtual directory where authentication should be
        # disabled.
        [Parameter(Mandatory)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

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
    Set-CIisConfigurationAttribute -LocationPath $LocationPath `
                                   -VirtualPath $VirtualPath `
                                   -SectionPath $sectionPath `
                                   -Name 'enabled' `
                                   -Value $false
}
