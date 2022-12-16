
function Set-CIisConfigurationAttribute
{
    <#
    .SYNOPSIS
    Sets attribute values on an IIS configuration section.

    .DESCRIPTION
    The `Set-CIisConfigurationAttribute` function can set a single attribute value or *all* attribute values on an IIS
    configuration section. To set a single attribute value, and leave all other attributes unchanged, pass the attribute
    name to the `Name` parameter and its value to the `Value` parameter. If the new value is different than the current
    value, the value is changed and saved in IIS's applicationHost.config file.

    To set *all* attributes on a configuration section, pass the attribute names and values in a hashtable to the
    `Attribute` parameter. Attributes in the hashtable will be updated to match the value in the hashtable. All other
    attributes will be reset to their default values.

    To set an attribute on a configuration section under a specific directory, application, or virtual path in a
    website, pass the virtual path to the directory, application, or virtual path to the `VirtualPath` parameter.

    `Set-CIisConfigurationAttribute` writes messages to PowerShell's information stream for each attribute whose value
    is changing, showing the current value and the new value. If an attribute's value is sensitive, use the `Sensitive`
    switch, and the attribute's current and new value will be masked with eight `*` characters.

    .EXAMPLE
    Set-CIisConfigurationAttribute -SiteName 'SiteOne' -SectionPath 'system.webServer/httpRedirect' -Name 'destination' -Value 'http://example.com'

    Demonstrates how to call `Set-CIisConfigurationAttribute` to set a single attribute value. In this example, the
    http redirect "destination" setting is set for site "SiteOne". All other attributes on
    `system.webServer/httpRedirect` are left unchanged.

    .EXAMPLE
    Set-CIisConfigurationAttribute -SiteName 'SiteTwo' -SectionPath 'system.webServer/httpRedirect' -Attribute @{ 'destination' = 'http://example.com'; 'httpResponseStatus' = 302 }

    Demonstrates how to set *all* attributes on a configuration section by pipling a hashtable of attribute names and
    values to `Set-CIisConfigurationAttribute`. In this example, the `destination` and `httpResponseStatus` attributes
    are set to `http://example.com` and `302`, respectively. All other attributes on `system.webServer/httpRedirect`
    are removed, whic resets them to their default value.

    .EXAMPLE
    Set-CIisConfigurationAttribute -SiteName 'SiteOne' -VirtualPath 'old_app' -SectionPath 'system.webServer/httpRedirect' -Name 'destination' -Value 'http://example.com'

    Demonstrates how to set attribute values on a sub-path in a website by passing the path to the `VirtualPath`
    parameter.

    .EXAMPLE
    Set-CIisConfigurationAttribute -ConfigurationElement (Get-CIisAppPool -Name 'DefaultAppPool').Cpu -Name 'limit' -Value 10000

    Demonstrates how to set attribute values on a configuration element object. In this case the "limit" setting for the
    "DefaultAppPool" application pool will be set. Use the `ConfigurationElement` parameter when you can't get a
    configuration section for what you want to update.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the website whose attribute values to configure.
        [Parameter(Mandatory, ParameterSetName='AllByConfigPath', Position=0)]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath', Position=0)]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Parameter(ParameterSetName='AllByConfigPath')]
        [Parameter(ParameterSetName='SingleByConfigPath')]
        [String] $VirtualPath = '',

        # The configuration section path to configure, e.g.
        # `system.webServer/security/authentication/basicAuthentication`. The path should *not* start with a forward
        # slash. You can also pass
        [Parameter(Mandatory, ParameterSetName='AllByConfigPath')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath')]
        [String] $SectionPath,

        [Parameter(Mandatory, ParameterSetName='AllByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigElement')]
        [Microsoft.Web.Administration.ConfigurationElement] $ConfigurationElement,

        # A hashtable whose keys are attribute names and the values are the attribute values. Any attribute *not* in
        # the hashtable is ignored, unless the `All` switch is present, in which case, any attribute *not* in the
        # hashtable is removed from the configuration section (i.e. reset to its default value).
        [Parameter(Mandatory, ParameterSetName='AllByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='AllByConfigPath')]
        [hashtable] $Attribute,

        # The target element the change is being made on. Used in messages written to the console. The default is to
        # use the type and tag name of the ConfigurationElement.
        [Parameter(ParameterSetName='AllByConfigElement')]
        [Parameter(ParameterSetName='AllByConfigPath')]
        [String] $Target,

        # Properties to skip and not change. These are usually private settings that we shouldn't be mucking with or
        # settings that capture current state, etc.
        [Parameter(ParameterSetName='AllByConfigElement')]
        [Parameter(ParameterSetName='AllByConfigPath')]
        [String[]] $Exclude = @(),

        # If set, each setting on the configuration element whose attribute isn't in the `Attribute` hashtable is
        # deleted, which resets it to its default value. Otherwise, configuration element attributes not in the
        # `Attributes` hashtable left in place and not modified.
        [Parameter(ParameterSetName='AllByConfigElement')]
        [Parameter(ParameterSetName='AllByConfigPath')]
        [switch] $Reset,

        # The name of the attribute whose value to set. Setting a single attribute will not affect any other attributes
        # in the configuration section. If you want other attribute values reset to default values, pass a hashtable
        # of attribute names and values to the `Attribute` parameter.
        [Parameter(Mandatory, ParameterSetName='SingleByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath')]
        [String] $Name,

        # The attribute's value. Setting a single attribute will not affect any other attributes in the configuration
        # section. If you want other attribute values reset to default values, pass a hashtable of attribute names and
        # values to the `Attribute` parameter.
        [Parameter(Mandatory, ParameterSetName='SingleByConfigElement')]
        [Parameter(Mandatory, ParameterSetName='SingleByConfigPath')]
        [AllowNull()]
        [AllowEmptyString()]
        [Object] $Value,

        # If the attribute's value is sensitive. If set, the attribute's value will be masked when written to the
        # console.
        [bool] $Sensitive
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function Set-AttributeValue
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [Microsoft.Web.Administration.ConfigurationAttribute] $InputObject,

            [AllowNull()]
            [AllowEmptyString()]
            [Object] $Value
        )

        begin
        {
            $mirroring = -not $PSBoundParameters.ContainsKey('Value')
        }

        process
        {
            $currentAttr = $InputObject

            if( $Exclude -and $currentAttr.Name -in $Exclude )
            {
                return
            }

            if( $mirroring )
            {
                # Should be the default value unless user has supplied a value.
                $Value = $currentAttr.Schema.DefaultValue
                if( $Attribute.ContainsKey($currentAttr.Name) )
                {
                    $Value = $Attribute[$currentAttr.Name]
                }
            }

            $currentValue = $currentAttr.Value

            $protectValue = $Sensitive -or $currentAttr.Name -eq 'password'
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
                $currentValueMsg = [Enum]::GetName($Value.GetType().FullName, $currentValue)
            }
            elseif( $currentAttr.Schema.Type -eq 'timeSpan' -and $Value -is [UInt64] )
            {
                $valueMsg = [TimeSpan]::New($Value)
            }

            if( $protectValue )
            {
                $currentValueMsg = '*' * 8
                $valueMsg = '*' * 8
            }

            $msgPrefix = "    @$($nameFormat -f $currentAttr.Name)  "
            $noChangeMsg = "$($msgPrefix)$($currentValueMsg) == $($valueMsg)"
            $changedMsg =  "$($msgPrefix)$($currentValueMsg) -> $($valueMsg)"

            # We're mirroring, so if value not supplied,
            if( $mirroring -and -not $Attribute.ContainsKey($currentAttr.Name) )
            {
                # and its value has never been supplied,
                if( $currentAttr.IsInheritedFromDefaultValue )
                {
                    # do nothing
                    Write-Debug $noChangeMsg
                    return
                }

                # Attribute was previously supplied but now it isn't, or, attribute value changed manually. Delete
                # attribute so its value reverts to IIS's default value.
                $infoMessages.Add($changedMsg)
                $action = "Remove Attribute"
                $whatIf = "$($currentAttr.Name) for $($Target -replace '"', '''')"
                if( $PSCmdlet.ShouldProcess($whatIf, $action) )
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
                        continue
                    }
                    [void]$removedNames.Add($currentAttr.Name)
                }
                return
            }

            if( $currentValue -eq $Value )
            {
                Write-Debug $noChangeMsg
                return
            }

            [void]$infoMessages.Add($changedMsg)
            try
            {
                $ConfigurationElement.SetAttributeValue($currentAttr.Name, $Value)
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
        if ($VirtualPath)
        {
            $functionName = $PSCmdlet.MyInvocation.MyCommand.Name
            $caller = Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1
            if ($caller.FunctionName -like '*-CIis*')
            {
                $functionName = $caller.FunctionName
            }

            $functionName = $PSCmdlet.MyInvocation.MyCommand.Name
            "The $($functionName) function''s ""SiteName"" and ""VirtualPath"" parameters are obsolete and have " +
            'been replaced with a single "LocationPath" parameter, which should be the combined path of the ' +
            'location/object to configure, e.g. ' +
            "``$($functionName) -LocationPath '$($LocationPath)/$($VirtualPath)'``." |
                Write-CIisWarningOnce

            $LocationPath = Join-CIisLocationPath -Path $LocationPath -ChildPath $VirtualPath
        }

        $ConfigurationElement = Get-CIisConfigurationSection -LocationPath $LocationPath -SectionPath $SectionPath
        if( -not $ConfigurationElement )
        {
            return
        }
    }

    $attrNameFieldLength =
        $ConfigurationElement.Attributes |
        Select-Object -ExpandProperty 'Name' |
        Select-Object -ExpandProperty 'Length' |
        Measure-Object -Maximum |
        Select-Object -ExpandProperty 'Maximum'

    $nameFormat = "{0,-$($attrNameFieldLength)}"

    $updatedNames = [Collections.ArrayList]::New()
    $removedNames = [Collections.ArrayList]::New()

    $infoMessages = [Collections.Generic.List[String]]::New()

    if( -not $SectionPath -and ($ConfigurationElement | Get-Member -Name 'SectionPath') )
    {
        $SectionPath = $ConfigurationElement.SectionPath
    }

    if( -not $Target )
    {
        if( $SectionPath )
        {
            $Target = $sectionPath
        }
        else
        {
            $Target = $ConfigurationElement.GetType().Name
        }
    }

    if( $Name )
    {
        $Name = "$($Name.Substring(0, 1).ToLowerInvariant())$($Name.Substring(1, $Name.Length - 1))"
        $ConfigurationElement.GetAttribute($Name) | Set-AttributeValue -Value $Value
    }
    else
    {
        $ConfigurationElement.Attributes |
            Where-Object {
                if( $Reset )
                {
                    return $true
                }

                return $Attribute.ContainsKey($_.Name)
            } |
            Sort-Object -Property 'Name' |
            Set-AttributeValue
    }

    $pluralSuffix = ''
    if( $updatedNames.Count -gt 1 )
    {
        $pluralSuffix = 's'
    }

    $whatIfTarget = "$($updatedNames -join ', ') for $($Target -replace '"', '''')"
    $action = "Set Attribute$($pluralSuffix)"
    $shouldCommit = $updatedNames -and $PSCmdlet.ShouldProcess($whatIfTarget, $action)

    if( $shouldCommit -or $removedNames )
    {
        if( $infoMessages.Count -eq 1 )
        {
            $msg = "Configuring $($Target): $($infoMessages.Trim() -replace ' {2,}', ' ')"
            Write-Information $msg
        }
        elseif( $infoMessages.Count -gt 1)
        {
            Write-Information "Configuring $($Target)."
            $infoMessages | ForEach-Object { Write-Information $_ }
        }
    }

    # Only save if we made any changes.
    if( $updatedNames -or $removedNames )
    {
        Save-CIisConfiguration
    }
}