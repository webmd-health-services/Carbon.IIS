
function Get-CIisDisplayPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $SectionPath,

        [String] $LocationPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($LocationPath)
    {
        return "${LocationPath}:${SectionPath}"
    }

    return $SectionPath
}