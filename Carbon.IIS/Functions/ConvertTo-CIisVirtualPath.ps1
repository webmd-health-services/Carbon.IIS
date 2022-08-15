
function ConvertTo-CIisVirtualPath
{
    <#
    .SYNOPSIS
    Turns a virtual path into a canonical virtual path like you would find in IIS's applicationHost.config

    .DESCRIPTION
    The `ConvertTo-CIisVirtualPath` takes in a path and converts it to a canonical virtual path as it would be saved to
    IIS's applicationHost.config:

    * duplicate directory separator characters are removed
    * relative path segments (e.g. `.` or `..`) are resolved and removed (i.e. `path/one/../two` changes to `path/two`)
    * all `\` characters are converted to `/`
    * Leading and trailing `/' characters are removed.
    * Adds a leading `/` character

    If you don't want a leading `/` character, use the `NoLeadingSlash` switch.

    .EXAMPLE
    "/some/path/" | ConvertTo-CIisVirtualPath

    Would return "/some/path".

    .EXAMPLE

    "path" | ConvertTo-CIisVirtualPath

    Would return "/path"

    .EXAMPLE

    "\some\path" | ConvertTo-CIisVirtualPath

    Would return "/some/path"
    #>
    [CmdletBinding()]
    param(
        # The path to convert/normalize.
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [String] $Path,

        # If true, omits the leading slash on the returned path. The default is to include a leading slash.
        [switch] $NoLeadingSlash
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $leadingSlash = '/'
        if( $NoLeadingSlash )
        {
            $leadingSlash = ''
        }

        # GetFullPath removes extra slashes, dots but prefixes a path with a root path (e.g. C:\ or /). We need to get
        # this system's root path so we can use GetFullPath to canonicalize our path, but remove the extra root path
        # prefix.
        $root = [IO.Path]::GetFullPath('/')
    }

    process
    {
        if( -not $Path )
        {
            return $leadingSlash
        }

        $indent = ' ' * $Path.Length
        Write-Debug "$($Path)  -->"

        $prevPath = $Path
        $Path = $Path | Split-Path -NoQualifier
        if( $Path -ne $prevPath )
        {
            Write-Debug "$($indent)   |-  $($Path)"
        }

        $prevPath = $Path
        if( [IO.Path]::GetFullPath.OverloadDefinitions.Count -eq 1 )
        {
            $Path = Join-Path -Path $root -ChildPath $Path
            $Path = [IO.Path]::GetFullPath($Path)
        }
        else
        {
            $Path = [IO.Path]::GetFullPath($Path, $root)
        }
        $Path = $Path.Substring($root.Length)
        if( $Path -ne $prevPath )
        {
            Write-Debug "$($indent)   |-  $($Path)"
        }

        $prevPath = $Path
        $Path = $Path.Replace('\', '/')
        if( $Path -ne $prevPath )
        {
            Write-Debug "$($indent)   |-  $($Path)"
        }

        $prevPath = $Path
        $Path = $Path.Trim('\', '/')
        if( $Path -ne $prevPath )
        {
            Write-Debug "$($indent)   |-  $($Path)"
        }

        $Path = "$($leadingSlash)$($Path)"
        Write-Debug "$($Path)$(' ' * ([Math]::Max(($indent.Length - $Path.Length), 0)))  <--"

        return $Path
    }
}