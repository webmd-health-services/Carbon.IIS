
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

        [String[]] $Exclude = @(),

        [switch] $Reset,

        [Parameter(Mandatory)]
        [ConfigurationElement] $Defaults,

        [switch] $AsDefaults
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $invocation = $SourceCmdlet.MyInvocation
    $cmd = $invocation.MyCommand

    $parameterSet = $cmd.ParameterSets | Where-Object 'Name' -EQ $SourceCmdlet.ParameterSetName
    if( -not $parameterSet )
    {
        $parameterSet = $cmd.ParameterSets | Where-Object 'IsDefault' -EQ $true
    }

    $cmdParameters = $invocation.BoundParameters

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
                                   -Exclude $Exclude `
                                   -Reset:$Reset `
                                   -Defaults $Defaults `
                                   -AsDefaults:$AsDefaults
}
