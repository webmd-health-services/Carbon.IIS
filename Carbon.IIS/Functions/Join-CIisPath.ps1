
function Join-CIisPath
{
    <#
    .SYNOPSIS
    Combines path segments into an IIS virtual/location path.

    .DESCRIPTION
    The `Join-CIisPath` function takes path segments and combines them into a single virtual/location path. You can pass
    the path segments as a list to the `Path` parameter, as multipe unnamed parameters, or pipe them in. The final path
    is normalized by removing extra slashes, relative path signifiers (e.g. `.` and `..`), and converting backward
    slashes to forward slashes.

    .EXAMPLE
    Join-CIisPath -Path 'SiteName', 'Virtual', 'Path'

    Demonstrates how to join paths together by passing an array of paths to the `Path` parameter.

    .EXAMPLE
    Join-CIisPath -Path 'SiteName' 'Virtual' 'Path'

    Demonstrates how to join paths together by passing each path as unnamed parameters.

    .EXAMPLE
    'SiteName', 'Virtual', 'Path' | Join-CIisPath

    Demonstrates how to join paths together by piping each path into the function.

    .EXAMPLE
    'SiteName', 'Virtual', 'Path' | Join-CIisPath -NoLeadingSlash

    Demonstrates how to omit the leading slash on the returned virtual/location path by using the `NoLeadingSlash`
    switch.
    #>
    [CmdletBinding()]
    param(
        # The parent path.
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]$Path,

        # All remaining arguments are passed to this parameter. Each path passed are also appended to the path. This
        # parameter exists to allow you to call `Join-CIisPath` with each path to join as a positional parameter, e.g.
        # `Join-Path -Path 'one' 'two' 'three' 'four' 'five' 'six'`.
        [Parameter(Position=1, ValueFromRemainingArguments)]
        [String[]] $ChildPath,

        # If set, the returned virtual path will have a leading slash. The default behavior is for the returned path
        # not to have a leading slash.
        [switch] $LeadingSlash
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $segments = [Collections.Generic.List[String]]::New()
    }

    process
    {
        if (-not $Path)
        {
            return
        }

        foreach ($pathItem in $Path)
        {
            if (-not $pathItem)
            {
                continue
            }

            $segments.Add($pathItem)
        }
    }

    end
    {
        $fullPath = (& {
                if ($segments.Count)
                {
                    $segments | Write-Output
                }

                if ($ChildPath)
                {
                    $ChildPath | Where-Object { $_ } | Write-Output
                }
        }) -join '/'
        return $fullPath | ConvertTo-CIisVirtualPath -NoLeadingSlash:(-not $LeadingSlash)
    }
}
