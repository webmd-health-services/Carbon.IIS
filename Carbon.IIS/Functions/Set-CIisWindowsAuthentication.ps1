
function Set-CIisWindowsAuthentication
{
    <#
    .SYNOPSIS
    Configures the settings for Windows authentication.

    .DESCRIPTION
    By default, configures Windows authentication on a website.  You can configure Windows authentication at a specific
    path under a website by passing the virtual path (*not* the physical path) to that directory.

    The changes only take effect if Windows authentication is enabled (see `Enable-CIisSecurityAuthentication`).

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://blogs.msdn.com/b/webtopics/archive/2009/01/19/service-principal-name-spn-checklist-for-kerberos-authentication-with-iis-7-0.aspx

    .LINK
    Disable-CIisSecurityAuthentication

    .LINK
    Enable-CIisSecurityAuthentication

    .EXAMPLE
    Set-CIisWindowsAuthentication -LocationPath 'Peanuts/Snoopy/DogHouse' -UseKernelMode $false

    Configures Windows authentication on the `Snoopy/Doghouse` directory of the `Peanuts` site to not use kernel mode.

    .EXAMPLE
    Set-CIisWindowsAuthentication -LocationPath 'Peanuts' -Reset

    Configures Windows authentication on the `Peanuts` website to not use the default kernel mode because the `Reset`
    switch is given and the `UseKernelMode` parameter is not.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='New')]
    param(
        # The site where Windows authentication should be set.
        [Parameter(Mandatory, Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath = '',

        # The value for the `authPersistNonNtlm` setting.
        [bool] $AuthPersistNonNtlm,

        # The value for the `authPersistSingleRequest` setting.
        [bool] $AuthPersistSingleRequest,

        # Enable Windows authentication. To disable Windows authentication you must explicitly set `Enabled` to
        # `$false`, e.g. `-Enabled $false`.
        [bool] $Enabled,

        # The value for the `useAppPoolCredentials` setting.
        [bool] $UseAppPoolCredentials,

        # The value for the `useKernelMode` setting.
        [Parameter(ParameterSetName='New')]
        [bool] $UseKernelMode,

        # OBSOLETE. Use the `UseKernelMode` parameter instead.
        [Parameter(ParameterSetName='Deprecated')]
        [switch] $DisableKernelMode,

        # If set, the anonymous authentication setting for each parameter *not* passed is deleted, which resets it to
        # its default value. Otherwise, anonymous authentication settings whose parameters are not passed are left in
        # place and not modified.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $attrs = @{}

    $settingNames = @(
        'authPersistNonNtlm',
        'authPersistSingleRequest',
        'enabled',
        'useAppPoolCredentials',
        'useKernelMode'
    )
    $attrs = $PSBoundParameters | Copy-Hashtable -Key $settingNames

    if ($PSCmdlet.ParameterSetName -eq 'Deprecated')
    {
        "The $($PSCmdlet.MyInvocation.MyCommand.Name) function's ""DisableKernelMode"" switch is obsolete and will " +
        'be removed in the next major version of Carbon.IIS. Use the new `UseKernelMode` parameter instead.' |
            Write-CIisWarningOnce

        $attrs['useKernelMode'] = -not $DisableKernelMode.IsPresent
    }

    if ($VirtualPath)
    {
        Write-CIisWarningOnce -ForObsoleteSiteNameAndVirtualPathParameter
    }

    $sectionPath = 'system.webServer/security/authentication/windowsAuthentication'
    Set-CIisConfigurationAttribute -LocationPath ($LocationPath, $VirtualPath | Join-CIisPath) `
                                   -SectionPath $sectionPath `
                                   -Attribute $attrs `
                                   -Reset:$Reset
}
