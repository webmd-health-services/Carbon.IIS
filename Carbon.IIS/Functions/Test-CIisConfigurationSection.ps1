
function Test-CIisConfigurationSection
{
    <#
    .SYNOPSIS
    Tests a configuration section.

    .DESCRIPTION
    You can test if a configuration section exists or wheter it is locked.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Test-CIisConfigurationSection -SectionPath 'system.webServer/I/Do/Not/Exist'

    Tests if a configuration section exists.  Returns `False`, because the given configuration section doesn't exist.

    .EXAMPLE
    Test-CIisConfigurationSection -SectionPath 'system.webServer/cgi' -Locked

    Returns `True` if the global CGI section is locked.  Otherwise `False`.

    .EXAMPLE
    Test-CIisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication' -SiteName `Peanuts` -VirtualPath 'SopwithCamel' -Locked

    Returns `True` if the `Peanuts` website's `SopwithCamel` sub-directory's `basicAuthentication` security authentication section is locked.  Otherwise, returns `False`.
    #>
    [CmdletBinding(DefaultParameterSetName='CheckExists')]
    param(
        [Parameter(Mandatory)]
        # The path to the section to test.
        [String] $SectionPath,

        # The name of the site whose configuration section to test.  Optional.  The default is the global configuration.
        [Parameter(Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

        # Test if the configuration section is locked.
        [Parameter(Mandatory, ParameterSetName='CheckLocked')]
        [switch] $Locked
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getArgs = @{}
    if ($LocationPath)
    {
        $getArgs['LocationPath'] = $LocationPath
        $getArgs['VirtualPath'] = $VirtualPath
    }

    $section = Get-CIisConfigurationSection -SectionPath $SectionPath @getArgs -ErrorAction SilentlyContinue

    if( $PSCmdlet.ParameterSetName -eq 'CheckExists' )
    {
        if( $section )
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    if( -not $section )
    {
        if ($VirtualPath)
        {
            $LocationPath = Join-CIisVirtualPath -Path $LocationPath -ChildPath $VirtualPath
        }
        Write-Error "IIS:$($LocationPath): section $($SectionPath) not found." -ErrorAction $ErrorActionPreference
        return
    }

    if( $PSCmdlet.ParameterSetName -eq 'CheckLocked' )
    {
        return $section.OverrideMode -eq 'Deny'
    }
}

