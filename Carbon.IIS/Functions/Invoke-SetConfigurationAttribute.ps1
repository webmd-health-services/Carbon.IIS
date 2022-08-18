
function Invoke-SetConfigurationAttribute
{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ConfigurationElement] $ConfigurationElement,

        [Parameter(Mandatory)]
        [Alias('PSCmdlet')]
        [PSCmdlet] $SourceCmdlet,

        [Parameter(Mandatory)]
        [String] $Target
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

    $attrs = @{}
    $cmdParameters = $invokation.BoundParameters
    foreach( $parameter in $parameterSet.Parameters )
    {
        $paramName = $parameter.Name
        if( -not $cmdParameters.ContainsKey($paramName) )
        {
            continue
        }

        $attrname = $paramName.Substring(0, 1).ToLowerInvariant() + $paramName.Substring(1)
        $attrs[$attrName] = $cmdParameters[$paramName]
    }

    Set-CIisConfigurationAttribute -ConfigurationElement $ConfigurationElement -Attribute $attrs -Target $Target
}
