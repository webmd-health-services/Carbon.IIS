
function Get-CIisDescription
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='ByConfigurationPath')]
        [ConfigurationElement] $ConfigurationElement,

        [Parameter(Mandatory, ParameterSetName='BySectionPath')]
        [String] $SectionPath,

        [String] $LocationPath,

        [Parameter(ParameterSetName='BySectionPath')]
        [String] $SubSectionPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $displayPath = Get-CIisDisplayPath -Argument $PSBoundParameters

    $type = 'configuration section'

    # Not a configuration section, so let's add a little more information.
    if ($ConfigurationElement -and -not ($ConfigurationElement | Get-Member -Name 'SectionPath'))
    {
        $type = ''

        $attrDesc = ''
        $name = $ConfigurationElement.Attributes['name']
        if ($name)
        {
            $attrDesc = " $($name.Value)"
        }
        else
        {
            $path = $ConfigurationElement.Attributes['path']
            if ($path)
            {
                $attrDesc = " $($path.Value)"
            }
        }
        $displayPath = "${displayPath}${attrDesc}"
    }

    return "IIS ${type} ${displayPath}"
}
