function Set-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Adds a new item to an IIS configuration collection.

    .DESCRIPTION
    The `Set-CIisCollectionItem` function adds a new item or updates the configuration of an existing IIS configuration
    collection item. Pipe the item value to the function, or pass it to the `InputObject` parameter. If the collection
    items you're configuring have only one attribute/value, pass just the value. Otherwise, pass a hashtable of
    attribute names/values. By default, only attributes passed in are added/set in the collection item. To delete any
    attributes not passed, use the `Strict` switch.

    To configure a collection that is part of a global configuration section, pass the configuration section's path to
    the `SectionPath` parameter. If the configuration section itself isn't a collection, pass the name of the collection
    to the `Name` parameter. To configure a configuration section for a specific site, directory, application, or
    virtual directory, pass its location path to the `LocationPath` parameter. To configure a specific
    `[Microsoft.Web.Administration.ConfigurationElement]` item (i.e. a site, application pool, etc.), pass that object
    to the `ConfigurationElement` parameter. If the configuration element itself isn't a collection, pass the name of
    the object' collection property to the `Name` parameter.

    When making changes directly to ConfigurationElement objects, test that those changes are saved correctly to the IIS
    application host configuration. Some configuration has to be saved at the same time as its parent configuration
    elements are created (i.e. sites, application pools, etc.). Use the `Suspend-CIisAutoCommit` and
    `Resume-CIisAutoCommit` functions to ensure configuration gets committed simultaneously.

    .EXAMPLE
    Add-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol/customHeaders' -Value 'X-Api-Header'

    Demonstrates how to add an item to a named collection under a configuration section. After the above command runs,
    this will be added to the applicationHost.config:

        <system.webServer>
            <httpProtocol>
                <customHeaders>
                    <add name='X-Api-Header' />
                </customHeaders>
            </httpProtocol>
        </system.webServer>


    .EXAMPLE
    Add-CIisCollectionItem -LocationPath 'SITE_NAME' -SectionPath 'system.webServer/defaultDocument' -CollectionName 'files' -Value 'hello.htm' -Attribute @{ 'name' = 'My File' }

    Demonstrates how to add an item to a named collection under a configuration section for a specific website,
    application, virtual directory, or directory. After the above command runs, this will be in the
    applicationHost.config:

        <location path="SITE_NAME">
            <system.webServer>
                <defaultDocument>
                    <files>
                        <add value="hello.htm" name="My File"/>
                    </files>
                </defaultDocument>
            </system.webServer>
        </location>


    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        [Parameter(Mandatory, ParameterSetName='Direct')]
        [ConfigurationElement] $ConfigurationElement,

        # The site to add the item to
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $LocationPath,

        # The path for the configuration section to edit
        [Parameter(Mandatory, ParameterSetName='Global')]
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $SectionPath,

        # The value for the IIS collection's identifying key.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $InputObject,

        # The name of the IIS collection to modify. If not provided, will use the SectionPath as the collection.
        [Alias('Name')]
        [String] $CollectionName,

        # If set, remove any attributes that aren't passed in.
        [switch] $Strict,

        # ***INTERNAL***. Do not use.
        [switch] $SkipCommit
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        function Write-Message
        {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [String] $Message
            )

            if (-not $firstLineWritten)
            {
                Write-Information $firstLine
                Set-Variable -Name 'firstLineWritten' -Value $true -Scope 1
            }

            if (-not $keyValueWritten)
            {
                Write-Information "    ${keyValue}"
                Set-Variable -Name 'keyValueWritten' -Value $true -Scope 1
            }

            Write-Information $Message
        }

        $firstLine = 'IIS configuration collection '
        $firstLineWritten = $false
        $keyValueWritten = $false

        $save = $false
        $collectionArgs = @{}

        $elementPath = ''
        if ($ConfigurationElement)
        {
            $firstLine = "${firstLine}$($ConfigurationElement.ElementTagName)"
            $collectionArgs['ConfigurationElement'] = $ConfigurationElement
            $elementPath = $ConfigurationElement.ElementTagName
            if (Get-Member -Name 'SectionPath' -InputObject $ConfigurationElement)
            {
                $elementPath = $ConfigurationElement.SectionPath
            }
        }
        else
        {
            $displayPath = Get-CIisDisplayPath -SectionPath $SectionPath `
                                               -LocationPath $locationPath `
                                               -SubSectionPath $CollectionName
            $firstLine = "${firstLine}${displayPath}"
            $elementPath = $SectionPath
            $collectionArgs['SectionPath'] = $SectionPath
            if ($LocationPath)
            {
                $collectionArgs['LocationPath'] = $LocationPath
            }
        }

        if ($CollectionName)
        {
            $elementPath = "${elementPath}/$($CollectionName)"
            $collectionArgs['Name'] = $CollectionName
        }

        $collection = Get-CIisCollection @collectionArgs

        if (-not $collection)
        {
            return
        }

        $keyAttrName = Get-CIisCollectionKeyName -Collection $collection

        if (-not $keyAttrName)
        {
            $msg = "Unable to find key for ${elementPath}."
            Write-Error -Message $msg
            return
        }

    }

    process
    {
        if (-not $collection)
        {
            return
        }

        if ($InputObject -isnot [IDictionary])
        {
            $InputObject = @{ $keyAttrName = $InputObject }
        }

        if (-not $InputObject.Contains($keyAttrName))
        {
            $msg = "Failed to add item to collection ""$($collection.Path)"" because the attributes of the item are " +
                   "missing a value for the key attribute ""${keyAttrName}""."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $keyValue = $InputObject[$keyAttrName]

        $item = $collection | Where-Object { $_.GetAttributeValue($keyAttrName) -eq $keyValue }

        if (-not $item)
        {
            $keyValueWritten = $true
            Write-Message "  + ${keyValue}"

            $item = $collection.CreateElement('add')
            foreach ($attrName in $InputObject.Keys)
            {
                if ($attrName -ne $keyAttrName)
                {
                    Write-Message "    + ${attrName}  $($InputObject[$attrName])"
                }
                $item.SetAttributeValue($attrName, $InputObject[$attrName])
            }
            [void]$collection.Add($item)
            $save = $true
        }
        else
        {
            $attrNameFieldLength =
                $InputObject.Keys |
                Select-Object -ExpandProperty 'Length' |
                Measure-Object -Maximum |
                Select-Object -ExpandProperty 'Maximum'
            $attrNameFormat = "{0,-${attrNameFieldLength}}"
            foreach ($attrName in $InputObject.Keys)
            {
                $expectedValue = $InputObject[$attrName]
                $actualValue = $item.GetAttributeValue($attrName)

                if ($expectedValue -eq $actualValue)
                {
                    continue
                }

                $flag = ' '
                $changeMsg = "${actualValue} -> ${expectedValue}"
                $isAddingAttr = $null -eq $actualValue -or '' -eq $actualValue
                if ($isAddingAttr)
                {
                    $flag = '+'
                    $changeMsg = $expectedValue
                }

                $attrDisplayName = $attrNameFormat -f $attrName
                Write-Message "      ${flag} ${attrDisplayName}  ${changeMsg}"
                $item.SetAttributeValue($attrName, $expectedValue)
                $save = $true
            }
        }

        if ($Strict)
        {
            foreach ($attr in $item.Attributes)
            {
                if ($InputObject.Contains($attr.Name))
                {
                    continue
                }

                Write-Message "    - $($attr.Name)"
                [void]$attr.Delete()
                $save = $true
            }
        }
    }

    end
    {
        if (-not $save)
        {
            return
        }

        if ($SkipCommit)
        {
            return $true
        }

        Save-CIisConfiguration
    }
}
