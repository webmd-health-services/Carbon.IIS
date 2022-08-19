
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
    Set-CIisHttpHeader -SiteName 'SopwithCamel' -Name 'X-Flown-By' -Value 'Snoopy'

    Sets or creates the `SopwithCamel` website's `X-Flown-By` HTTP header to the value `Snoopy`.

    .EXAMPLE
    Set-CIisHttpHeader -SiteName 'SopwithCamel' -VirtualPath 'Engine' -Name 'X-Powered-By' -Value 'Root Beer'

    Sets or creates the `SopwithCamel` website's `Engine` sub-directory's `X-Powered-By` HTTP header to the value `Root Beer`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website where the HTTP header should be set/created.
        $SiteName,

        [string]
        # The optional path under `SiteName` where the HTTP header should be set/created.
        $VirtualPath = '',

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the HTTP header.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The value of the HTTP header.
        $Value
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $httpProtocol = Get-CIisConfigurationSection -SiteName $SiteName `
                                                 -VirtualPath $VirtualPath `
                                                 -SectionPath 'system.webServer/httpProtocol'
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

    $fullPath = Join-CIisVirtualPath $SiteName $VirtualPath
    Save-CIisConfiguration -Target "IIS Website '$($fullPath)'" -Action "$($action) $($Name) HTTP Header"
}

