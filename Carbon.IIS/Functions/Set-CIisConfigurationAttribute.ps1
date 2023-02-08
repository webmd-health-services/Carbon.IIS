
function Set-CIisConfigurationAttribute
{
    <#
    .SYNOPSIS
    Sets attribute values on an IIS configuration section.

    .DESCRIPTION
    The `Set-CIisConfigurationAttribute` function can set a single attribute value or *all* attribute values on an IIS
    configuration section. Pass the virtual/location path of the website, application, virtual directory, or directory
    to configure to the `LocationPath` parameter. Pass the path to the configuration section to update to the
    `SectionPath` parameter. To set a single attribute value, and leave all other attributes unchanged, pass the
    attribute name to the `Name` parameter and its value to the `Value` parameter. If the new value is different than
    the current value, the value is changed and saved in IIS's applicationHost.config file inside a `location` section.

    To set *all* attributes on a configuration section, pass the attribute names and values in a hashtable to the
    `Attribute` parameter. Attributes in the hashtable will be updated to match the value in the hashtable. All other
    attributes will be left unchanged. You can delete attributes from the configuration section that aren't in the
    attributes hashtable by using the `Reset` switch. Deleting attributes reset them to their default values.

    To configure a global configuration section, omit the `LocationPath` parameter, or pass a
    `Microsoft.Web.Administration.ConfigurationElement` object to the `ConfigurationElement` parameter.

    `Set-CIisConfigurationAttribute` writes messages to PowerShell's information stream for each attribute whose value
    is changing, showing the current value and the new value. If an attribute's value is sensitive, use the `Sensitive`
    switch, and the attribute's current and new value will be masked with eight `*` characters.

    .EXAMPLE
    Set-CIisConfigurationAttribute -LocationPath 'SiteOne' -SectionPath 'system.webServer/httpRedirect' -Name 'destination' -Value 'http://example.com'

    Demonstrates how to call `Set-CIisConfigurationAttribute` to set a single attribute value for a website,
    application, virtual directory, or directory. In this example, the `SiteOne` website's http redirect "destination"
    setting is set `http://example.com`. All other attributes on the website's `system.webServer/httpRedirect` are left
    unchanged.

    .EXAMPLE
    Set-CIisConfigurationAttribute -LocationPath 'SiteTwo' -SectionPath 'system.webServer/httpRedirect' -Attribute @{ 'destination' = 'http://example.com'; 'httpResponseStatus' = 302 }

    Demonstrates how to set multiple attributes on a configuration section by piping a hashtable of attribute names and
    values to `Set-CIisConfigurationAttribute`. In this example, the `destination` and `httpResponseStatus` attributes
    are set to `http://example.com` and `302`, respectively. All other attributes on `system.webServer/httpRedirect`
    are preserved.

    .EXAMPLE
    Set-CIisConfigurationAttribute -LocationPath 'SiteTwo' -SectionPath 'system.webServer/httpRedirect' -Attribute @{ 'destination' = 'http://example.com' } -Reset

    Demonstrates how to delete attributes that aren't passed to the `Attribute` parameter by using the `Reset` switch.
    In this example, the "SiteTwo" website's HTTP Redirect setting's destination attribute is set to
    `http://example.com`, and all its other attributes (if they exist) are deleted (e.g. `httpResponseStatus`,
    `childOnly`, etc.), which resets the deleted attributes to their default values.

    .EXAMPLE
    Set-CIisConfigurationAttribute -SectionPath 'system.webServer/httpRedirect' -Name 'destination' -Value 'http://example.com'

    Demonstrates how to set attribute values on a global configuration section by omitting the `LocationPath`
    parameter. In this example, the global HTTP redirect destination is set to `http://example.com`.

    .EXAMPLE
    Set-CIisConfigurationAttribute -ConfigurationElement (Get-CIisAppPool -Name 'DefaultAppPool').Cpu -Name 'limit' -Value 10000

    Demonstrates how to set attribute values on a configuration element object by passing the object to the
    `ConfigurationElement` parameter. In this case the "limit" setting for the "DefaultAppPool" application pool will be
    set.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website whose attribute values to configure.
        [Parameter(Mandatory, ParameterSetName='AllByConfigPath', Position=0)]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath', Position=0)]
        [String] $LocationPath,

        # The configuration section path to configure, e.g.
        # `system.webServer/security/authentication/basicAuthentication`. The path should *not* start with a forward
        # slash. You can also pass
        [Parameter(Mandatory, ParameterSetName='AllByConfigPath')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath')]
        [Parameter(Mandatory, ParameterSetName='AllForSection')]
        [Parameter(Mandatory, ParameterSetName='SingleForSection')]
        [String] $SectionPath,

        [Parameter(Mandatory, ParameterSetName='AllByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigElement')]
        [Microsoft.Web.Administration.ConfigurationElement] $ConfigurationElement,

        # A hashtable whose keys are attribute names and the values are the attribute values. Any attribute *not* in
        # the hashtable is ignored, unless the `All` switch is present, in which case, any attribute *not* in the
        # hashtable is removed from the configuration section (i.e. reset to its default value).
        [Parameter(Mandatory, ParameterSetName='AllByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='AllByConfigPath')]
        [Parameter(Mandatory, ParameterSetName='AllForSection')]
        [hashtable] $Attribute,

        # The target element the change is being made on. Used in messages written to the console. The default is to
        # use the type and tag name of the ConfigurationElement.
        [Parameter(ParameterSetName='AllByConfigElement')]
        [Parameter(ParameterSetName='AllByConfigPath')]
        [Parameter(ParameterSetName='AllForSection')]
        [String] $Target,

        # Properties to skip and not change. These are usually private settings that we shouldn't be mucking with or
        # settings that capture current state, etc.
        [Parameter(ParameterSetName='AllByConfigElement')]
        [Parameter(ParameterSetName='AllByConfigPath')]
        [Parameter(ParameterSetName='AllForSection')]
        [String[]] $Exclude = @(),

        # If set, each setting on the configuration element whose attribute isn't in the `Attribute` hashtable is
        # deleted, which resets it to its default value. Otherwise, configuration element attributes not in the
        # `Attributes` hashtable left in place and not modified.
        [Parameter(ParameterSetName='AllByConfigElement')]
        [Parameter(ParameterSetName='AllByConfigPath')]
        [Parameter(ParameterSetName='AllForSection')]
        [switch] $Reset,

        # The name of the attribute whose value to set. Setting a single attribute will not affect any other attributes
        # in the configuration section. If you want other attribute values reset to default values, pass a hashtable
        # of attribute names and values to the `Attribute` parameter.
        [Parameter(Mandatory, ParameterSetName='SingleByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath')]
        [Parameter(Mandatory, ParameterSetName='SingleForSection')]
        [String] $Name,

        # The attribute's value. Setting a single attribute will not affect any other attributes in the configuration
        # section. If you want other attribute values reset to default values, pass a hashtable of attribute names and
        # values to the `Attribute` parameter.
        [Parameter(Mandatory, ParameterSetName='SingleByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath')]
        [Parameter(Mandatory, ParameterSetName='SingleForSection')]
        [AllowNull()]
        [AllowEmptyString()]
        [Object] $Value,

        # If the attribute's value is sensitive. If set, the attribute's value will be masked when written to the
        # console.
        [bool] $Sensitive
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # Attributes whose default value in IIS schema isn't the actual default value. These are the actual default values.
    $realDefaults = @{
        [ApplicationPoolProcessModel] = @{
            'idleTimeout' = [TimeSpan]::Zero;
            'pingInterval' = (New-TimeSpan -Seconds 30);
            'pingResponseTime' = (New-TimeSpan -Minutes 1 -Seconds 30);
            'shutdownTimeLimit' = (New-TimeSpan -Minutes 1 -Seconds 30);
            'startupTimeLimit' = (New-TimeSpan -Minutes 1 -Seconds 30);
        };
        [ApplicationPoolPeriodicRestart] = @{
            'privateMemory' = [UInt32]2097152;
            'time' = [TimeSpan]::Zero;
        };
        [ApplicationPool] = @{
            'managedRuntimeVersion' = 'v4.0';
        }
    }

    function Get-TypeName
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [AllowNull()]
            [AllowEmptyString()]
            [Object] $InputObject
        )

        process
        {
            if ($null -eq $InputObject)
            {
                return ''
            }

            return "[$($InputObject.GetType().FullName -replace 'System\.', '')]"
        }
    }

    function Get-DisplayValue
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [AllowNull()]
            [AllowEmptyString()]
            [Object] $InputObject
        )

        process
        {
            if ($null -eq $InputObject)
            {
                return " (null)"
            }

            if ($InputObject -is [String] -and [String]::IsNullOrEmpty($InputObject))
            {
                return " (empty)"
            }

            if ($Sensitive -or $InputObject -is [securestring])
            {
                return "********"
            }

            if ($InputObject -is [Enum])
            {
                $valueAsEnum = [Enum]::Parse($InputObject.GetType().Name, $InputObject, $true)
                return "$($InputObject.ToString()) ($($valueAsEnum.ToString('D')))"
            }

            if ($Value -is [switch])
            {
                return "$($Value.IsPresent)"
            }

            return "$($InputObject.ToString())"
        }
    }

    function Set-AttributeValue
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [Microsoft.Web.Administration.ConfigurationElement] $Element,

            [Parameter(Mandatory)]
            [Alias('Key')]
            [String] $Name,

            [AllowNull()]
            [AllowEmptyString()]
            [Object] $Value
        )

        if( $Exclude -and $Name -in $Exclude )
        {
            return
        }

        $Name = "$($Name.Substring(0, 1).ToLowerInvariant())$($Name.Substring(1, $Name.Length - 1))"

        $currentAttr = $Element.Attributes[$Name]

        if (-not $currentAttr)
        {
            $locationPathMsg = ''
            if ($Element.LocationPath)
            {
                $locationPathMsg = " at location ""$($Element.LocationPath)"""
            }
            "Unable to set attribute ""$($Name)"" on configuration element ""$($Element.SectionPath)""" +
                "$($locationPathMsg) because that attribute doesn't exist on that element. Valid attributes are: " +
                "$(($Element.Attributes | Select-Object -ExpandProperty 'Name') -join ', ')." |
                Write-Error -ErrorAction $ErrorActionPreference
            return
        }

        $currentValue = $currentAttr.Value
        $noCurrentValue = $null -eq $currentValue
        $hasCurrentValue = -not $noCurrentValue
        $currentValueMsg = $currentValue | Get-DisplayValue

        $defaultValue = $currentAttr.Schema.DefaultValue
        $configElementType = $ConfigurationElement.GetType()
        if ($realDefaults.ContainsKey($configElementType) -and $realDefaults[$configElementType].ContainsKey($Name))
        {
            $defaultValue = $realDefaults[$configElementType][$Name]
        }
        $defaultValueMsg = $defaultValue | Get-DisplayValue
        $currentValueIsDefault = $currentValue -eq $defaultValue

        $valueMsg = $Value | Get-DisplayValue

        $newValue = $Value
        if ($newValue -is [securestring])
        {
            $newValue = [pscredential]::New('i', $newValue).GetNetworkCredential().Password
            $currentValueMsg = '********'
        }

        if ($Sensitive -or $currentAttr.Name -eq 'password')
        {
            $valueMsg = '********'
            $currentValueMsg = '********'
        }

        $msgPrefix = "    @$($nameFormat -f $currentAttr.Name)  "
        $emptyPrefixMsg = ' ' * $msgPrefix.Length

        Write-Debug "$($msgPrefix     )  current  $($currentValue | Get-TypeName) $($currentValueMsg)"
        Write-Debug "$($emptyPrefixMsg)  default  $($defaultValue | Get-TypeName) $($defaultValueMsg)"
        Write-Debug "$($emptyPrefixMsg)  new      $($newValue | Get-TypeName       ) $($valueMsg)"

        $whatIfTarget = "@$($currentAttr.Name) for $($Target -replace '"', '''')"

        if (-not $PSBoundParameters.ContainsKey('Value') -and $hasCurrentValue)
        {
            if ($currentValueIsDefault)
            {
                return
            }

            $deletedMsg = "$($msgPrefix)- $($currentValueMsg)"
            $infoMessages.Add($deletedMsg)
            $action = "Remove Attribute"
            if ($PSCmdlet.ShouldProcess($whatIfTarget, $action))
            {
                try
                {
                    $currentAttr.Delete()
                }
                catch
                {
                    $msg = "Exception resetting ""$($currentAttr.Name)"" on $($Target) to its default value (by " +
                            "deleting it): $($_)"
                    Write-Error -Message $msg
                    return
                }
                [void]$updatedNames.Add($currentAttr.Name)
            }
            return
        }

        if ($currentValue -eq $newValue)
        {
            return
        }

        $changedMsg =  "$($msgPrefix)$($currentValueMsg) -> $($valueMsg)"
        if ($noCurrentValue)
        {
            $changedMsg = "$($msgPrefix)+ $($valueMsg)"
        }
        [void]$infoMessages.Add($changedMsg)
        if ($PSCmdlet.ShouldProcess($whatIfTarget, 'Set Attribute'))
        {
            try
            {
                $ConfigurationElement.SetAttributeValue($currentAttr.Name, $newValue)
            }
            catch
            {
                $msg = "Exception setting ""$($currentAttr.Name)"" on $($Target): $($_)"
                Write-Error -Message $msg -ErrorAction Stop
            }
            [void]$updatedNames.Add($currentAttr.Name)
        }
    }

    if (-not $ConfigurationElement)
    {
        $locationPathArg = @{}
        if ($LocationPath)
        {
            $locationPathArg['LocationPath'] = $LocationPath
        }
        $ConfigurationElement = Get-CIisConfigurationSection -SectionPath $SectionPath @locationPathArg
        if( -not $ConfigurationElement )
        {
            return
        }
    }

    $isConfigSection = $null -ne ($ConfigurationElement | Get-Member -Name 'SectionPath')
    if( -not $SectionPath -and $isConfigSection )
    {
        $SectionPath = $ConfigurationElement.SectionPath
    }

    $attrNameFieldLength =
        $ConfigurationElement.Attributes |
        Select-Object -ExpandProperty 'Name' |
        Select-Object -ExpandProperty 'Length' |
        Measure-Object -Maximum |
        Select-Object -ExpandProperty 'Maximum'

    $nameFormat = "{0,-$($attrNameFieldLength)}"

    $updatedNames = [Collections.ArrayList]::New()

    $infoMessages = [Collections.Generic.List[String]]::New()

    if (-not $Target)
    {
        if( $SectionPath )
        {
            $Target = $sectionPath
        }
        else
        {
            $Target = $ConfigurationElement.GetType().Name
        }

        if ($LocationPath)
        {
            $Target = "$($Target) at location ""$($LocationPath)"""
        }
    }

    if ($Name)
    {
        Set-AttributeValue -Element $ConfigurationElement -Name $Name -Value $Value
    }
    else
    {
        $attrNames = $Attribute.Keys | Sort-Object
        foreach ($attrName in $attrNames)
        {
            Set-AttributeValue -Element $ConfigurationElement -Name $attrName -Value $Attribute[$attrName]
        }

        if ($Reset)
        {
            $attrNamesToDelete =
                $ConfigurationElement.Attributes |
                Where-Object 'Name' -NotIn $attrNames |
                Select-Object -ExpandProperty 'Name' |
                Sort-Object

            foreach ($attrName in ($attrNamesToDelete))
            {
                Set-AttributeValue -Element $ConfigurationElement -Name $attrName
            }
        }
    }

    if ($updatedNames)
    {
        Write-Information "Configuring $($Target):"
        $infoMessages | ForEach-Object { Write-Information $_ }

        if (-not $WhatIfPreference)
        {
            Save-CIisConfiguration
        }
    }
}