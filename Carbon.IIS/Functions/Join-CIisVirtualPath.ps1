
function Join-CIisVirtualPath
{
    <#
    .SYNOPSIS
    OBSOLETE. Use `Join-CIisPath` instead.

    .DESCRIPTION
    OBSOLETE. Use `Join-CIisPath` instead.
    #>
    [CmdletBinding()]
    param(
        # The parent path.
        [Parameter(Mandatory, Position=0)]
        [AllowEmptyString()]
        [AllowNull()]
        [String]$Path,

        #
        [Parameter(Position=1)]
        [String[]] $ChildPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $msg = 'The "Join-CIisVirtualPath" function is OBSOLETE and will be removed in the next major version of ' +
           'Carbon.IIS. Please use the `Join-CIisPath` function instead.'
    Write-CIisWarningOnce -Message $msg

    if( $ChildPath )
    {
        $Path = Join-Path -Path $Path -ChildPath $ChildPath
    }
    $Path.Replace('\', '/').Trim('/')
}
