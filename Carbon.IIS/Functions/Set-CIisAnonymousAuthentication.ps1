function Set-CIisAnonymousAuthentication
{
    <#
    .SYNOPSIS
    Configures anonymous authentication for all or part of a website.

    .DESCRIPTION
    The `Set-CIisAnonymousAuthentication` function configures anonymous authentication for all or part of a website.
    Pass the name of the site to the `SiteName` parameter. To enable anonymous authentication, use the `Enabled` switch.
    To set the identity to use for anonymous access, pass the identity's username to the `UserName` and password to the
    `Pasword` parameters. To set the logon method for the anonymous user, use the `LogonMethod` parameter.

    To configure anonymous authentication on a path/application/virtual directory under a website, pass the virtual path
    to that path/application/virtual directory to the `VirtualPath` parameter.

    .EXAMPLE
    Set-CIisAnonymousAuthentication -SiteName 'MySite' -Enabled -UserName 'MY_IUSR' -Password $password -LogonMethod Interactive

    Demonstrates how to use `Set-CIisAnonymousAuthentication` to configure all attributes of anonymous authentication:
    it is enabled with the `Enabled` switch, the idenity of anonymous access is set to `MY_IUSR` whose password is
    $password, with a logon method of `Interactive`.

    .EXAMPLE
    Set-CIisAnonymousAuthentication -SiteName 'MySite' -VirtualPath 'allowAll' -Enabled

    Demonstrates how to use `Set-CIisAnonymousAuthentication` to configure anonymous authentication on a
    path/application/virtual directry under a site. In this example, anonymous authentication is enabled in the `MySite`
    website's `allowAll` path/application/virtual directory.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website whose anonymous authentication settings to change.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The path to a directory/application/virtual diectory under the `SiteName` website whose anonymous
        # authentication settings to change.
        [String] $VirtualPath = '',

        # Enable anonymous authentication. To disable anonymous authentication you must explicitly set `Enabled to
        # `$false`, e.g. `-Enabled:$false`.
        [switch] $Enabled,

        # The username of the identity to use to run anonymous requests.
        [String] $UserName,

        # The password username of the identity to use to run anonymous requests. Not needed if using system accounts.
        [SecureString] $Password,

        # The logon method to use for anonymous access.
        [Microsoft.Web.Administration.AuthenticationLogonMethod] $LogonMethod
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $paramNames = @('enabled', 'logonMethod', 'password', 'userName')

    $sectionPath = 'system.webServer/security/authentication/anonymousAuthentication'

    $PSBoundParameters.GetEnumerator() |
        Where-Object 'Key' -In $paramNames |
        Set-CIisConfigurationAttribute -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath $sectionPath
}
