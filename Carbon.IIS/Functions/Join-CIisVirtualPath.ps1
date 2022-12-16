
function Join-CIisVirtualPath
{
    <#
    .SYNOPSIS
    Combines paths into an IIS virtual path.

    .DESCRIPTION
    The `Join-CIisVirtualPath` function takes path segments and combines them into a single virtual path. You can pass
    the path segments as a list to the `Path` parameter, as multipe unnamed parameters, or piped in.

    Removes extra slashes and relative path signifiers (e.g. `.` and `..`).  Converts backward slashes to forward
    slashes.

    .EXAMPLE
    Join-CIisVirtualPath -Path 'SiteName', 'Virtual', 'Path'

    Demonstrates how to join paths together by passing an array of paths to the `Path` parameter.

    .EXAMPLE
    Join-CIisVirtualPath -Path 'SiteName' 'Virtual' 'Path'

    Demonstrates how to join paths together by passing each path as unnamed parameters.

    .EXAMPLE
    'SiteName', 'Virtual', 'Path' | Join-CIisVirtualPath

    Demonstrates how to join paths together by piping each path into the function.
    #>
    [CmdletBinding()]
    param(
        # The parent path.
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]$Path,

        #
        [Parameter(Position=1, ValueFromRemainingArguments)]
        [String[]] $ChildPath
    )

    begin
    {
        $segments = [Collections.Generic.List[String]]::New()
    }

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

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
        (& {
                if ($segments.Count)
                {
                    $segments | Write-Output
                }

                if ($ChildPath)
                {
                    $ChildPath | Where-Object { $_ } | Write-Output
                }
        } |
        ConvertTo-CIisVirtualPath -NoLeadingSlash) -join '/'

    }
}

Set-Alias -Name 'Join-CIisLocationPath' -Value 'Join-CIisVirtualPath'