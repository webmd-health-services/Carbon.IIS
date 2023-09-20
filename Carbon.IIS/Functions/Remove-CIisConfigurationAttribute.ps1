
function Remove-CIisConfigurationAttribute
{
    <#
    .SYNOPSIS
    Removes an attribute from a configuration section.

    .DESCRIPTION
    The `Remove-CIisConfigurationAttribute` function removes an attribute from a configuration section in the IIS
    application host configuration file. Pass the configuration section path to the `SectionPath` parameter, and the
    names of the attributes to remove to the `Name` parameter (or pipe the names to
    `Remove-CIisConfigurationAttribute`). The function deletes that attribute. If the attribute doesn't exist, nothing
    happens.

    To delete/remove an attribute from the configuration of an application/virtual directory under a website, pass the
    application/virtual diretory's name/path to the `VirtualPath` parameter.

    To remove an attribute from an arbitrary configuration element, pass the configuration element to the
    `ConfigurationElement` parameter. You must also pass the xpath to that element to the `ElementXpath` parameter
    because the Microsoft.Web.Administration API doesn't expose a way to determine if an attribute no longer exists in
    the applicationHost.config file, so `Remove-CIisConfigurationAttribute` has to check.

    .EXAMPLE
    Remove-CIisConfigurationAttribute -SiteName 'MySite' -SectionPath 'system.webServer/security/authentication/anonymousAuthentication' -Name 'userName'

    Demonstrates how to delete/remove the attribute from a website's configuration. In this example, the `userName`
    attribute on the `system.webServer/security/authentication/anonymousAuthentication` configuration is deleted.

    .EXAMPLE
    Remove-CIisConfigurationAttribute -SiteName 'MySite' -VirtualPath 'myapp/appdir' -SectionPath 'system.webServer/security/authentication/anonymousAuthentication' -Name 'userName'

    Demonstrates how to delete/remove the attribute from a website's path/application/virtual directory configuration.
    In this example, the `userName` attribute on the `system.webServer/security/authentication/anonymousAuthentication`
    for the '/myapp/appdir` directory is removed.

    .EXAMPLE
    Remove-CIisConfigurationAttribute -ConfigurationElement $vdir -ElementXpath "system.applicationHost/sites/site[@name = 'site']/application[@path = '/']/virtualDirectory[@path = '/']" -Name 'logonMethod'

    Demonstrates how to remove an attribute from an arbitrary configuration element. In this example, the `logonMethod`
    attribute will be removed from the `site` site's default virtual directory.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The configuration element whose attribute to remove.
        [Parameter(Mandatory, ParameterSetName='ByConfigurationElement')]
        [ConfigurationElement] $ConfigurationElement,

        # The xpath expression to the configuration element in the applicationHost.config file, without the
        # `/configuration` root path. The Microsoft.Web.Administration API doesn't expose a way to check if an attribute
        # is defined or is missing and has its default value. This xpath expression is used to check if an attribute
        # exists or not.
        [Parameter(Mandatory, ParameterSetName='ByConfigurationElement')]
        [String] $ElementXpath,

        # The name of the website to configure.
        [Parameter(Mandatory, Position=0, ParameterSetName='BySectionPath')]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Parameter(ParameterSetName='BySectionPath')]
        [String] $VirtualPath = '',

        # The configuration section path to configure, e.g.
        # `system.webServer/security/authentication/basicAuthentication`. The path should *not* start with a forward
        # slash.
        [Parameter(Mandatory, ParameterSetName='BySectionPath')]
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

        $desc = ''
        if ($ConfigurationElement)
        {
            $desc = Get-CIisDescription -ConfigurationElement $ConfigurationElement
        }
        else
        {
            $ConfigurationElement = Get-CIisConfigurationSection -SectionPath $SectionPath `
                                                                 -LocationPath $LocationPath `
                                                                 -VirtualPath $VirtualPath
            if( -not $ConfigurationElement )
            {
                return
            }

            $desc = Get-CIisDescription -SectionPath $SectionPath -LocationPath $LocationPath
        }

        $attrNameFieldLength =
            $ConfigurationElement.Attributes |
            Select-Object -ExpandProperty 'Name' |
            Select-Object -ExpandProperty 'Length' |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty 'Maximum'
        $nameFormat = "{0,-$($attrNameFieldLength)}"

        $save = $false
    }

    process
    {
        if( -not $ConfigurationElement )
        {
            return
        }

        $shownDescription = $false
        Write-Debug $desc

        foreach( $nameItem in $Name )
        {
            $attr = $ConfigurationElement.Attributes[$nameItem]
            if( -not $attr )
            {
                $msg = "${desc} doesn't have a ""${nameItem}"" attribute."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            $nameItem = "$($nameItem.Substring(0, 1).ToLowerInvariant())$($nameItem.Substring(1, $nameItem.Length -1))"

            $msg = "    $($nameFormat -f $nameItem)]  $($attr.IsInheritedFromDefaultValue)  $($attr.Value)  " +
                   "$($attr.Schema.DefaultValue)"
            Write-Debug $msg

            $exists = $false
            if ($PSCmdlet.ParameterSetName -eq 'ByConfigurationElement')
            {
                $exists = Test-CIisApplicationHostElement -Xpath "${ElementXpath}/@${nameItem}"
            }
            else
            {
                $exists =
                    Test-CIisApplicationHostElement -Xpath "${SectionPath}/@${nameItem}" -LocationPath $LocationPath
            }

            if (-not $exists)
            {
                Write-Verbose "Attribute ${nameItem} on ${desc} does not exist."
                continue
            }

            $target = "$($nameItem) on ${desc}"
            $action = 'Remove Attribute'
            if( $PSCmdlet.ShouldProcess($target, $action) )
            {
                if (-not $shownDescription)
                {
                    Write-Information $desc
                    $shownDescription = $true
                }
                Write-Information "  - ${nameItem}"
                $attr.Delete()
                $save = $true
            }
        }
    }

    end
    {
        if (-not $ConfigurationElement)
        {
            return
        }

        if (-not $save)
        {
            return
        }

        Save-CiisConfiguration
    }
}