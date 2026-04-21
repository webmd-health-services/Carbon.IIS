
function Get-CIisCommandArgument
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='Command')]
        [Management.Automation.FunctionInfo] $Command,

        [Parameter(Mandatory, ParameterSetName='CommandName')]
        [String] $Name,

        [hashtable] $Argument,

        [String[]] $Exclude
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $Command)
    {
        $Command = Get-Command -Name $Name -Module 'Carbon.IIS' -CommandType Function -ErrorAction Stop
    }

    $cmdArgs = @{}
    foreach ($cmdParamName in $Command.Parameters.Keys)
    {
        $argName = $cmdParamName
        if (-not $Argument.ContainsKey($argName))
        {
            $aliasName = $Command.Parameters[$cmdParamName].Aliases | Where-Object { $Argument.ContainsKey($_) }
            if (-not $aliasName)
            {
                continue
            }

            $argName = $aliasName
        }

        if ($Exclude -and ($Exclude | Where-Object { $argName -like $_ }))
        {
            continue
        }

        $cmdArgs[$cmdParamName] = $Argument[$argName]
    }

    return $cmdArgs
}