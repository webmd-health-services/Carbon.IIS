
function Join-CIisVirtualPath
{
    <#
    .SYNOPSIS
    Combines a path and a child path for an IIS website, application, virtual directory into a single path.

    .DESCRIPTION
    Removes extra slashes and relative path signifiers (e.g. `.` and `..`).  Converts backward slashes to forward
    slashes.

    .EXAMPLE
    Join-CIisVirtualPath -Path 'SiteName' -ChildPath 'Virtual/Path'

    Demonstrates how to join two IIS paths together.  Returns `SiteName/Virtual/Path`.
    #>
    [CmdletBinding()]
    param(
        # The parent path.
        [Parameter(Mandatory, Position=0)]
        [String]$Path,

        # The child path.
        [Parameter(Mandatory, Position=1)]
        [AllowEmptyString()]
        [AllowNull()]
        [String] $ChildPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Path = $Path | ConvertTo-CIisVirtualPath -NoLeadingSlash
    if( $ChildPath )
    {
        $ChildPath = $ChildPath | ConvertTo-CIisVirtualPath -NoLeadingSlash
    }

    if( $Path -and $ChildPath )
    {
        return "$($Path)/$($ChildPath)"
    }
    elseif( $Path )
    {
        return $Path
    }
    elseif( $ChildPath )
    {
        return $ChildPath
    }
    return ''
}

Set-Alias -Name 'Join-CIisLocationPath' -Value 'Join-CIisVirtualPath'