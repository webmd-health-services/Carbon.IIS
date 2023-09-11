
function Remove-CIisConfigurationAttribute
{
    <#
    .SYNOPSIS
    Removes an attribute from a configuration section.

    .DESCRIPTION
    The `Remove-CIisConfigurationAttribute` function removes/deletes an attribute from a website's configuration in the
    IIS application host configuration file. Pass the website name to the `SiteName` parameter, the path to the
    configuration section from which to remove the attribute to the `SectionPath` parameter, and the name of the
    attribute to remove/delete to the `Name` parameter. The function deletes that attribute. If the attribute doesn't
    exist, nothing happens.

    To delete more than one attribute on a specific element at a ttime, either pass multiple names to the `Name`
    parameter, or pipe the list of attributes to `Remove-CIisConfigurationAttribute`.

    To delete/remove an attribute from the configuration of an application/virtual directory under a website, pass the
    application/virtual diretory's name/path to the `VirtualPath` parameter.

    .EXAMPLE
    Remove-CIisConfigurationAttribute -SiteName 'MySite' -SectionPath 'system.webServer/security/authentication/anonymousAuthentication' -Name 'userName'

    Demonstrates how to delete/remove the attribute from a website's configuration. In this example, the `userName`
    attribute on the `system.webServer/security/authentication/anonymousAuthentication` configuration is deleted.

    .EXAMPLE
    Remove-CIisConfigurationAttribute -SiteName 'MySite' -VirtualPath 'myapp/appdir' -SectionPath 'system.webServer/security/authentication/anonymousAuthentication' -Name 'userName'

    Demonstrates how to delete/remove the attribute from a website's path/application/virtual directory configuration.
    In this example, the `userName` attribute on the `system.webServer/security/authentication/anonymousAuthentication`
    for the '/myapp/appdir` directory is removed.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website to configure.
        [Parameter(Mandatory, Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [String] $VirtualPath = '',

        # The configuration section path to configure, e.g.
        # `system.webServer/security/authentication/basicAuthentication`. The path should *not* start with a forward
        # slash.
        [Parameter(Mandatory)]
        [String] $SectionPath,

        # The name of the attribute to remove/clear. If the attribute doesn't exist, nothing happens.
        #
        # You can pipe multiple names to clear/remove multiple attributes.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('Key')]
        [String[]] $Name
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $section =
            Get-CIisConfigurationSection -LocationPath $LocationPath -VirtualPath $VirtualPath -SectionPath $SectionPath
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

        $attrNames = [Collections.Arraylist]::New()

        $locationPathMsg = $LocationPath
        if ($VirtualPath)
        {
            $locationPathMsg = Join-CIisPath -Path $LocationPath, $VirtualPath
        }
        $basePrefix = "[IIS:/Sites/$($locationPathMsg):$($SectionPath)"
    }

    process
    {
        if( -not $section )
        {
            return
        }

        foreach( $nameItem in $Name )
        {
            $attr = $section.Attributes[$nameItem]
            if( -not $attr )
            {
                $msg = "IIS configuration section ""$($SectionPath)"" doesn't have a ""$($nameItem)"" attribute."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            $nameItem = "$($nameItem.Substring(0, 1).ToLowerInvariant())$($nameItem.Substring(1, $nameItem.Length -1))"
            $msgPrefix = "$($basePrefix)$($nameFormat -f $nameItem)]  "

            Write-Debug "$($msgPrefix)$($attr.IsInheritedFromDefaultValue)  $($attr.Value)  $($attr.Schema.DefaultValue)"
            $hasDefaultValue = $attr.Value -eq $attr.Schema.DefaultValue
            if( -not $attr.IsInheritedFromDefaultValue -and -not $hasDefaultValue )
            {
                [void]$attrNames.Add($nameItem)
            }

            $pathMsg = ''
            if( $VirtualPath )
            {
                $pathMsg = ", path '$($VirtualPath)'"
            }

            $target =
                "$($nameItem) from IIS website '$($LocationPath)'$($pathMsg), configuration section '$($SectionPath)'"
            $action = 'Remove Attribute'
            if( $PSCmdlet.ShouldProcess($target, $action) )
            {
                $msg =  "Removing attribute $($target -replace '''', '"')"
                Write-Information $msg
                # Fortunately, only actually persists changes to applicationHost.config if there are any changes.
                $attr.Delete()
            }
        }
    }
}