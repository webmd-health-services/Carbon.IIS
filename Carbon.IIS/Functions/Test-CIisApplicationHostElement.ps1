
function Test-CIisApplicationHostElement
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $XPath,

        [String] $LocationPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $xml = [xml](Get-Content -Path $script:applicationHostPath -Raw)
    $element = $xml.DocumentElement
    if ($LocationPath)
    {
        $element = $element.SelectSingleNode("location[@path = ""$($LocationPath.TrimStart('/'))""]")
        if (-not $element)
        {
            return $false
        }
    }

    $element = $element.SelectSingleNode($XPath)
    if ($element)
    {
        return $true
    }

    return $false
}