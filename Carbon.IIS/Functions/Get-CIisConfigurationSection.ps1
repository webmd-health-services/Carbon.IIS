
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
        [Parameter(Mandatory, ParameterSetName='ForSite', Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Parameter(ParameterSetName='ForSite')]
        [Alias('Path')]
        [String] $VirtualPath,

        # The path to the configuration section to return.
        [Parameter(Mandatory, ParameterSetName='ForSite')]
        [Parameter(Mandatory, ParameterSetName='Global')]
        [String] $SectionPath,

        # The type of object to return.  Optional.
        [Type] $Type = [Microsoft.Web.Administration.ConfigurationSection]
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = Get-CIisServerManager
    $config = $mgr.GetApplicationHostConfiguration()

    $section = $null
    try
    {
        if ($PSCmdlet.ParameterSetName -eq 'ForSite')
        {
            if ($VirtualPath)
            {
                $functionName = $PSCmdlet.MyInvocation.MyCommand.Name
                $caller = Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1
                if ($caller.FunctionName -like '*-CIis*')
                {
                    $functionName = $caller.FunctionName
                }

                "The $($functionName) function''s ""SiteName"" and ""VirtualPath"" parameters are obsolete and have " +
                'been replaced with a single "LocationPath" parameter, which should be the combined path of the ' +
                'location/object to configure, e.g. ' +
                "``$($functionName) -LocationPath '$($LocationPath)/$($VirtualPath)'``." |
                    Write-CIisWarningOnce

                $LocationPath = Join-CIisPath -Path $LocationPath, $VirtualPath
            }

            $LocationPath = $LocationPath | ConvertTo-CIisVirtualPath
            $section = $config.GetSection( $SectionPath, $Type, $LocationPath )
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
        if (-not ($section | Get-Member -Name 'LocationPath'))
        {
            $section | Add-Member -Name 'LocationPath' -MemberType NoteProperty -Value ''
        }
        if ($LocationPath)
        {
            $section.LocationPath = $LocationPath
        }
        return $section
    }
    else
    {
        $msg = 'IIS:{0}: configuration section {1} not found.' -f $LocationPath,$SectionPath
        Write-Error $msg -ErrorAction $ErrorActionPreference
        return
    }
}

