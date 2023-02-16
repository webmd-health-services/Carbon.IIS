
function Split-CIisLocationPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]] $VirtualPath
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $VirtualPath)
        {
            return
        }

        return ($VirtualPath | ConvertTo-CIisVirtualPath -NoLeadingSlash).Split('/', 2)
    }

}