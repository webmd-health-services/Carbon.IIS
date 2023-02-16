
function Get-CIisHttpHeader
{
    <#
    .SYNOPSIS
    Gets the HTTP headers for a website or directory under a website.

    .DESCRIPTION
    For each custom HTTP header defined under a website and/or a sub-directory under a website, returns an object with
    these properties:

     * Name: the name of the HTTP header
     * Value: the value of the HTTP header

    .LINK
    Set-CIisHttpHeader

    .EXAMPLE
    Get-CIisHttpHeader -LocationPath SopwithCamel

    Returns the HTTP headers for the `SopwithCamel` website.

    .EXAMPLE
    Get-CIisHttpHeader -LocationPath 'SopwithCamel/Engine'

    Returns the HTTP headers for the `Engine` directory under the `SopwithCamel` website.

    .EXAMPLE
    Get-CIisHttpHeader -LocationPath SopwithCambel -Name 'X-*'

    Returns all HTTP headers which match the `X-*` wildcard.
    #>
    [CmdletBinding()]
    param(
        # The name of the website whose headers to return.
        [Parameter(Mandatory, Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

        # The name of the HTTP header to return.  Optional.  If not given, all headers are returned.  Wildcards
        # supported.
        [String] $Name = '*'
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sectionPath = 'system.webServer/httpProtocol'

    $httpProtocol =
        Get-CIisConfigurationSection -LocationPath $LocationPath -VirtualPath $VirtualPath -SectionPath $sectionPath

    $httpProtocol.GetCollection('customHeaders') |
        Where-Object { $_['name'] -like $Name } |
        ForEach-Object {
            $header = [pscustomobject]@{ Name = $_['name']; Value = $_['value'] }
            $header.pstypenames.Insert(0, 'Carbon.Iis.HttpHeader')
            $header | Write-Output
        }
}

