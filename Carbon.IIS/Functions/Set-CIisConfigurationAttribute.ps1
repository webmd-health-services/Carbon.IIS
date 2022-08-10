
function Set-CIisConfigurationAttribute
{
    <#
    .SYNOPSIS
    Sets attribute values on an IIS configuration section.

    .DESCRIPTION
    The `Set-CIisConfigurationAttribute` function sets attribute values on an IIS configuration section. Pass the
    website name whose configuration to change to the `SiteName` parameter. Pass the path to the configuration section
    to the `SectionPath` parameter. Pass the name of the attribute to the `Name` parameter and the value to the `Value`
    parameter. If the new value is different than the current value, the value is updated and saved in IIS's
    applicationHost.config file.

    To set an attribute on a configuration section under a specific directory, application, or virtual path in a
    website, pass the virtual path to the directory, application, or virtual path to the `VirtualPath` parameter.

    You can pipe multiple attributes to `Set-CIisConfigurationAttribute` with a hashtable. Instead of piping the
    hashtable itself, pipe the hashtable's enumerator:

        $attributes.GetEnumerator() | Set-CIisConfigurationAttribute

    If an attribute's value is sensitive, use the `Sensitive` switch. This will prevent the attribute's value from
    being written to the console.

    .EXAMPLE
    Set-CIisConfigurationAttribute -SiteName 'SiteOne' -SectionPath 'system.webServer/httpRedirect' -Name 'destination' -Value 'http://example.com'

    Demonstrates how to call `Set-CIisConfigurationAttribute` to set a single attribute value. In this example, the
    http redirect "destination" setting is set for site "SiteOne".

    .EXAMPLE
    @{ 'destination' = 'http://example.com'; 'httpResponseStatus' = 302 }.GetEnumerator)() | Set-CIisConfigurationAttribute -SiteName 'SiteTwo' -SectionPath 'system.webServer/httpRedirect'

    Demonstrates how to set multiple attribute values on a configuration section by piping the enumerator of a hasthable
    to `Set-CIisConfigurationAttibute`.

    .EXAMPLE
    @([pscustomobject]@{ Name = 'destination'; Value = 'http://example.com'}) | Set-CIisConfigurationAttribute -SiteName 'SiteTwo' -SectionPath 'system.webServer/httpRedirect'

    Demonstrates how to set multiple attribute values on a configuration section by piping objects with `Name` and
    `Value` properties to `Set-CIisConfigurationAttibute`.

    .EXAMPLE
    Set-CIisConfigurationAttribute -SiteName 'SiteOne' -VirtualPath 'old_app' -SectionPath 'system.webServer/httpRedirect' -Name 'destination' -Value 'http://example.com'

    Demonstrates how to set attribute values on a sub-path in a website by passing the path to the `VirtualPath`
    parameter.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website whose attribute values to configure.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The virtual path to a directory, application, or virtual directory whose attribute values to configure.
        [String] $VirtualPath = '',

        # The configuration section path to configure, e.g.
        # `system.webServer/security/authentication/basicAuthentication`. The path should *not* start with a forward
        # slash.
        [Parameter(Mandatory)]
        [String] $SectionPath,

        # The name of the attribute whose value to set.
        #
        # You can pipe objects with `Name` and `Value` properties to `Get-CIisConfigurationAttribute` to set multiple
        # attribute values at once.
        #
        # You can use a hashtable to also set multiple attributes at once by piping the hashtable's enumerator to
        # `Get-CIisConfigurationSection`, e.g. `@{}.GetEnumerator() | Set-CIisConfigurationAttribute`.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Key')]
        [String] $Name,

        # The attribute's value.
        #
        # You can pipe objects with `Name` and `Value` properties to `Get-CIisConfigurationAttribute` to set multiple
        # attribute values at once.
        #
        # You can use a hashtable to also set multiple attributes at once by piping the hashtable's enumerator to
        # `Get-CIisConfigurationSection`, e.g. `@{}.GetEnumerator() | Set-CIisConfigurationAttribute`.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [AllowEmptyString()]
        [Object] $Value,

        # If the attribute's value is sensitive. If set, the attribute's value will be masked when written to the
        # console.
        [bool] $Sensitive
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
        $section = Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath $SectionPath
        if( -not $section )
        {
            return
        }

        $attrNameFieldLength =
            $section.Attributes |
            Select-Object -ExpandProperty 'Name' |
            Select-Object -ExpandProperty 'Length' |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty 'Maximum'
        $nameFormat = "{0,-$($attrNameFieldLength)}"

        $attrNames = [Collections.ArrayList]::New()
        $commitChanges = $false

        $basePrefix = "[IIS:/Sites/$(Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath):$($SectionPath)"
    }

    process
    {
        if( -not $section )
        {
            return
        }

        $Name = "$($Name.Substring(0, 1).ToLowerInvariant())$($Name.Substring(1, $Name.Length -1))"

        $msgPrefix = "$($basePrefix)@$($nameFormat -f $Name)]  "

        $currentValue = $section.GetAttributeValue($Name)

        $protectValue = $Sensitive
        if( $Value -is [SecureString] )
        {
            $Value = [pscredential]::New('i', $Value).GetNetworkCredential().Password
            $protectValue = $true
        }
        elseif( $Value -is [switch] )
        {
            $Value = $Value.IsPresent
        }

        $currentValueMsg = $currentValue
        $valueMsg = $Value

        if( $Value -is [Enum] )
        {
            $currentValueMsg = [enum]::GetName($Value.GetType().FullName, $currentValue)
        }

        if( $protectValue )
        {
            $currentValueMsg = '*' * 8
            $valueMsg = '*' * 8
        }

        if( $currentValue -eq $Value )
        {
            Write-Debug "$($msgPrefix)$($currentValueMsg) == $($valueMsg)"
            return
        }

        Write-Information "$($msgPrefix)$($currentValueMsg) -> $($valueMsg)"
        $section.SetAttributeValue( $Name, $Value )
        [void]$attrNames.Add($Name)
        $commitChanges = $true
    }

    end
    {
        if( -not $section )
        {
            return
        }

        $pathMsg = ''
        if( $VirtualPath )
        {
            $pathMsg = " path '$($VirtualPath)'"
        }

        $pluralSuffix = ''
        if( $attrNames.Count -gt 1 )
        {
            $pluralSuffix = 's'
        }
        $target = "IIS website '$($SiteName)'$($pathMsg) configuration section '$($SectionPath)'"
        $action = "set attribute$($pluralSuffix) '$($attrNames -join ''', ''')'"
        if( $commitChanges -and $PSCmdlet.ShouldProcess($target, $action) )
        {
            $section.CommitChanges()
        }
    }

}