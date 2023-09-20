
function Get-CIisDescription
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='ByConfigurationPath')]
        [ConfigurationElement] $ConfigurationElement,

        [Parameter(Mandatory, ParameterSetName='BySectionPath')]
        [String] $SectionPath,

        [Parameter(ParameterSetName='BySectionPath')]
        [String] $LocationPath,

        [Parameter(ParameterSetName='BySectionPath')]
        [String] $SubSectionPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    function Get-LocationDescription
    {
        [CmdletBinding()]
        param(
            [String] $LocationPath
        )

        if (-not $LocationPath)
        {
            return ''
        }

        return " for location ""${LocationPath}"""
    }

    if ($ConfigurationElement)
    {
        $SectionPath = ''
        $LocationPath = ''
        $SubSectionPath = ''

        if ($ConfigurationElement | Get-Member -Name 'SectionPath')
        {
            $SectionPath = $ConfigurationElement.SectionPath
        }

        $locationDesc = ''
        if ($ConfigurationElement | Get-Member -Name 'LocationPath')
        {
            $LocationPath = $ConfigurationElement.LocationPath
        }

        if (-not $SectionPath)
        {
            $locationDesc = Get-LocationDescription -LocationPath $LocationPath

            $name = $ConfigurationElement.Attributes['name']
            if ($name)
            {
                $name = " ""$($name.Value)"""
            }
            else
            {
                $name = $ConfigurationElement.Attributes['path']
                if ($name)
                {
                    $name = " $($name.Value)"
                }
            }
            return "IIS configuration element $($ConfigurationElement.ElementTagName)${name}${locationDesc}"
        }
    }

    $sectionDesc = $SectionPath.Trim('/')
    if ($SubSectionPath)
    {
        $sectionDesc = "${sectionDesc}/$($SubSectionPath.Trim('/'))"
    }

    $locationDesc = Get-LocationDescription -LocationPath $LocationPath

    return "IIS configuration section ${sectionDesc}${locationDesc}"
}
