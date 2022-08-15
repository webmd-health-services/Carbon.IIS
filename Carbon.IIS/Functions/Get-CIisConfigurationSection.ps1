
function Get-CIisConfigurationSection
{
    <#
    .SYNOPSIS
    Gets a Microsoft.Web.Adminisration configuration section for a given site and path.

    .DESCRIPTION
    Uses the Microsoft.Web.Administration API to get a `Microsoft.Web.Administration.ConfigurationSection`.

    .OUTPUTS
    Microsoft.Web.Administration.ConfigurationSection.

    .EXAMPLE
    Get-CIisConfigurationSection -SiteName Peanuts -Path Doghouse -Path 'system.webServer/security/authentication/anonymousAuthentication'

    Returns a configuration section which represents the Peanuts site's Doghouse path's anonymous authentication
    settings.
    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        # The site whose configuration should be returned.
        [Parameter(Mandatory, ParameterSetName='ForSite')]
        [String] $SiteName,

        # The optional site path whose configuration should be returned.
        [Parameter(ParameterSetName='ForSite')]
        [String] $VirtualPath = '',

        # The path to the configuration section to return.
        [Parameter(Mandatory, ParameterSetName='ForSite')]
        [Parameter(Mandatory, ParameterSetName='Global')]
        [String] $SectionPath,

        # The type of object to return.  Optional.
        [Type] $Type = [Microsoft.Web.Administration.ConfigurationSection]
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-CIisServerManager
    $config = $mgr.GetApplicationHostConfiguration()

    $section = $null
    $qualifier = ''
    try
    {
        if( $PSCmdlet.ParameterSetName -eq 'ForSite' )
        {
            $qualifier = Join-CIisVirtualPath $SiteName $VirtualPath
            $section = $config.GetSection( $SectionPath, $Type, $qualifier )
        }
        else
        {
            $section = $config.GetSection( $SectionPath, $Type )
        }
    }
    catch
    {
    }

    if( $section )
    {
        $section | Add-IisServerManagerMember -ServerManager $mgr -PassThru
    }
    else
    {
        $msg = 'IIS:{0}: configuration section {1} not found.' -f $qualifier,$SectionPath
        Write-Error $msg -ErrorAction $ErrorActionPreference
        return
    }
}

