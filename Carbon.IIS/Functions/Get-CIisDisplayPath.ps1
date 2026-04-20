
function Get-CIisDisplayPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='ByArguments')]
        [hashtable] $Argument,

        [Parameter(Mandatory, ParameterSetName='ByConfigurationElement')]
        [Object] $ConfigurationElement,

        [Parameter(Mandatory, ParameterSetName='BySectionPath')]
        [String] $SectionPath,

        [String] $LocationPath,

        [String] $SubSectionPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($Argument)
    {
        if ($Argument.ContainsKey('ConfigurationElement'))
        {
            $ConfigurationElement = $Argument['ConfigurationElement']
        }
        elseif ($Argument.ContainsKey('SectionPath'))
        {
            $SectionPath = $Argument['SectionPath']
        }

        foreach ($optionalParamName in @('LocationPath', 'SubSectionPath'))
        {
            if (-not $Argument.ContainsKey($optionalParamName))
            {
                continue
            }
            Set-Variable -Name $optionalParamName -Value $Argument[$optionalParamName] -WhatIf:$false
        }
    }

    if ($ConfigurationElement)
    {
        $path = $ConfigurationElement.ElementTagName
        if (,$ConfigurationElement | Get-Member -Name 'SectionPath')
        {
            $path = $ConfigurationElement.SectionPath
        }
    }
    else
    {
        $path = $SectionPath
    }

    $path = $path.Trim('/')

    if ($LocationPath)
    {
        $path = "$($LocationPath | ConvertTo-CIisVirtualPath):${path}"
    }

    if ($SubSectionPath)
    {
        $path = "${path}/$($SubSectionPath.Trim('/'))"
    }

    return $path
}