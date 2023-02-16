
function Set-CIisHttpHeader
{
    <#
    .SYNOPSIS
    Sets an HTTP header for a website or a directory under a website.

    .DESCRIPTION
    If the HTTP header doesn't exist, it is created.  If a header exists, its value is replaced.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Get-CIisHttpHeader

    .EXAMPLE
    Set-CIisHttpHeader -LocationPath 'SopwithCamel' -Name 'X-Flown-By' -Value 'Snoopy'

    Sets or creates the `SopwithCamel` website's `X-Flown-By` HTTP header to the value `Snoopy`.

    .EXAMPLE
    Set-CIisHttpHeader -LocationPath 'SopwithCamel/Engine' -Name 'X-Powered-By' -Value 'Root Beer'

    Sets or creates the `SopwithCamel` website's `Engine` sub-directory's `X-Powered-By` HTTP header to the value `Root Beer`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website where the HTTP header should be set/created.
        [Parameter(Mandatory, Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Alias('Path')]
        [String] $VirtualPath,

        # The name of the HTTP header.
        [Parameter(Mandatory)]
        [String] $Name,

        # The value of the HTTP header.
        [Parameter(Mandatory)]
        [String] $Value
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sectionPath = 'system.webServer/httpProtocol'
    $httpProtocol =
        Get-CIisConfigurationSection -LocationPath $locationPath -VirtualPath $VirtualPath -SectionPath $sectionPath
    $headers = $httpProtocol.GetCollection('customHeaders')
    $header = $headers | Where-Object { $_['name'] -eq $Name }

    if( $header )
    {
        $action = 'Set'
        $header['name'] = $Name
        $header['value'] = $Value
    }
    else
    {
        $action = 'Add'
        $addElement = $headers.CreateElement( 'add' )
        $addElement['name'] = $Name
        $addElement['value'] = $Value
        [void] $headers.Add( $addElement )
    }

    if ($VirtualPath)
    {
        $LocationPath = Join-CIisPath -Path $LocationPath, $VirtualPath
    }
    Save-CIisConfiguration -Target "IIS Website '$($LocationPath)'" -Action "$($action) $($Name) HTTP Header"
}

