
function Lock-CIisConfigurationSection
{
    <#
    .SYNOPSIS
    Locks an IIS configuration section so that it can't be modified/overridden by individual websites.

    .DESCRIPTION
    Locks configuration sections globally so they can't be modified by individual websites.  For a list of section paths, run

        C:\Windows\System32\inetsrv\appcmd.exe lock config /section:?

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Lock-CIisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication'

    Locks the `basicAuthentication` configuration so that sites can't override/modify those settings.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the section to lock.  For a list of sections, run
        #
        #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
        [Parameter(Mandatory)]
        [String[]] $SectionPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    foreach( $sectionPathItem in $SectionPath )
    {
        $section = Get-CIisConfigurationSection -SectionPath $sectionPathItem
        $section.OverrideMode = 'Deny'
        Save-CIisConfiguration -Target $sectionPathItem -Action 'Locking IIS Configuration Section'
    }
}

