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
    to the `CollectionName` parameter. To configure a configuration section for a specific site, directory, application,
    or virtual directory, pass its location path to the `LocationPath` parameter. To configure a specific
    `[Microsoft.Web.Administration.ConfigurationElement]` item (i.e. a site, application pool, etc.), pass that object
    to the `ConfigurationElement` parameter. If the configuration element itself isn't a collection, pass the name of
    the object' collection property to the `CollectionName` parameter.

    When making changes directly to ConfigurationElement objects, test that those changes are saved correctly to the IIS
    application host configuration. Some configuration has to be saved at the same time as its parent configuration
    elements are created (i.e. sites, application pools, etc.). Use the `Suspend-CIisAutoCommit` and
    `Resume-CIisAutoCommit` functions to ensure configuration gets committed simultaneously.

    .EXAMPLE
    Set-CIisCollectionItem -SectionPath 'system.webServer/defaultDocument' -CollectionName 'files' -Value 'welcome.html'

    Demonstrates how to add an item to a configuration collection under a configuration section. This example will add
    "welcome.html" to the list of default documents.

    .EXAMPLE
    Set-CIisCollectionItem -LocationPath 'example.com' -SectionPath 'system.webServer/defaultDocument' -CollectionName 'files' -Value 'welcome.html'

    Demonstrates how to add an item to a site, directory, application, or virtual directory by using the `LocationPath`
    parameter. In this example, the "example.com" website will be configured to include "welcome.html" as a default
    document.

    .EXAMPLE
    @{ 'name' = 'X-Example' ; value = 'example' } | Set-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol/customHeaders' -CollectionName 'files'

    Demonstrates how to add items that have multiple attributes by piping a hashtable of attribute names/values to
    the function. In this example, `Set-CIIsCollectionItem` will add `X-Example` HTTP header with a value of `example`
    to global configuration.
    #>
    [CmdletBinding(DefaultParameterSetName='BySectionPath')]
    param(
        # The `[Microsoft.Web.Administration.ConfigurationElement]` object to get as a collection or the parent element
        # of the collection element to get. If this is the parent element, pass the name of the child element collection
        # to the `CollectionName` parameter.
        [Parameter(Mandatory, ParameterSetName='ByConfigurationElement')]
        [ConfigurationElement] $ConfigurationElement,

        # The path to the collection's configuration section.
        [Parameter(Mandatory, ParameterSetName='BySectionPath')]
        [String] $SectionPath,

        # The location path to the site, directory, application, or virtual directory to configure. By default, the
        # global configuration will be updated.
        [Parameter(ParameterSetName='BySectionPath')]
        [String] $LocationPath,

        # The value for the IIS collection's identifying key.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $InputObject,

        # The name of the IIS collection to modify. If not provided, will use the SectionPath as the collection.
        [Alias('Name')]
        [String] $CollectionName,

        # The attribute name for the attribute that uniquely identifies each item in a collection. This is usually
        # automatically detected.
        [String] $UniqueKeyAttributeName,

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

        if (-not $UniqueKeyAttributeName)
        {
            $UniqueKeyAttributeName = Get-CIisCollectionKeyName -Collection $collection

            if (-not $UniqueKeyAttributeName)
            {
                $msg = "Failed to set IIS configuration collection ${displayPath} because it does not have a unique " +
                       'key attribute. Use the "UniqueKeyAttributeName" parameter to specify the attribute name.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }
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
            $InputObject = @{ $UniqueKeyAttributeName = $InputObject }
        }

        if (-not $InputObject.Contains($UniqueKeyAttributeName))
        {
            $msg = "Failed to add item to collection ""$($collection.Path)"" because the attributes of the item are " +
                   "missing a value for the key attribute ""${UniqueKeyAttributeName}""."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $keyValue = $InputObject[$UniqueKeyAttributeName]

        $item = $collection | Where-Object { $_.GetAttributeValue($UniqueKeyAttributeName) -eq $keyValue }

        if (-not $item)
        {
            $keyValueWritten = $true
            Write-Message "  + ${keyValue}"

            $addElementName = $collection.Schema.AddElementNames
            $item = $collection.CreateElement($addElementName)
            foreach ($attrName in $InputObject.Keys)
            {
                if ($attrName -ne $UniqueKeyAttributeName)
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
