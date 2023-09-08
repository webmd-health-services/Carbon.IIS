
function Get-CIisDisplayPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $SectionPath,

        [String] $LocationPath,

        [String] $SubSectionPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $path = $SectionPath.Trim('/')
    if ($LocationPath)
    {
        $path = "${LocationPath}:${path}"
    }

    if ($SubSectionPath)
    {
        $path = "${path}/$($SubSectionPath.Trim('/'))"
    }

    return $path
}