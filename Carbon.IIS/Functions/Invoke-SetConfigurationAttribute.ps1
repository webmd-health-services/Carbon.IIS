
function Invoke-SetConfigurationAttribute
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ConfigurationElement] $ConfigurationElement,

        [Parameter(Mandatory)]
        [Alias('PSCmdlet')]
        [PSCmdlet] $SourceCmdlet,

        [Parameter(Mandatory)]
        [String] $Target,

        [hashtable] $Attribute = @{},

        [String[]] $Exclude = @()
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $invokation = $SourceCmdlet.MyInvocation
    $cmd = $invokation.MyCommand

    $parameterSet = $cmd.ParameterSets | Where-Object 'Name' -EQ $SourceCmdlet.ParameterSetName
    if( -not $parameterSet )
    {
        $parameterSet = $cmd.ParameterSets | Where-Object 'IsDefault' -EQ $true
    }

    $cmdParameters = $invokation.BoundParameters

    foreach( $attrName in ($ConfigurationElement.Attributes | Select-Object -ExpandProperty 'Name') )
    {
        if( -not $cmdParameters.ContainsKey($attrName) -or $attrName -in $Exclude )
        {
            continue
        }

        $Attribute[$attrName] = $cmdParameters[$attrName]
    }

    Set-CIisConfigurationAttribute -ConfigurationElement $ConfigurationElement `
                                   -Attribute $Attribute `
                                   -Target $Target `
                                   -Exclude $Exclude
}
