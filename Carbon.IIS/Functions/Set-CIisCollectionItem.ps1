function Set-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Adds a new item to an IIS configuration collection.

    .DESCRIPTION
    The `Set-CIisCollectionItem` function adds a new item or updates the configuration of an existing IIS configuration
    collection item. Pipe the item value to the function, or pass it to the `InputObject` parameter. If the collection
    items you're configuring have only one attribute/value, pass just the value. Otherwise, pass a hashtable of
    attribute names/values.

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

        # ***INTERNAL***. Do not use.
        [switch] $SkipCommit
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $save = $false
        $msgs = [System.Collections.ArrayList] @()
        $collectionArgs = @{}
        $msgPrefix = 'IIS configuration collection '

        $elementPath = ''
        if ($ConfigurationElement)
        {
            $msgPrefix = "${msgPrefix}$($ConfigurationElement.ElementTagName)"
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
            $msgPrefix = "${msgPrefix}${displayPath}"
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

        [void]$msgs.Add($msgPrefix)

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
            $item = $collection.CreateElement('add')
            foreach ($attrName in $InputObject.Keys)
            {
                $item.SetAttributeValue($attrName, $InputObject[$attrName])
            }
            [void]$collection.Add($item)
            [void]$msgs.Add("  + ${keyAttrName} = ${keyValue}")
            $save = $true
        }

        foreach ($attrName in $InputObject.Keys)
        {
            $expectedValue = $InputObject[$attrName]
            $actualValue = $item.GetAttributeValue($attrName)

            if ($null -eq $actualValue)
            {
                [void]$msgs.Add("      + ${attrName} = ${expectedValue}")
                $item.SetAttributeValue($attrName, $expectedValue)
                $save = $true
                continue
            }
            elseif ($expectedValue -ne $actualValue)
            {
                [void]$msgs.Add("      ${attrName}  $($actualValue) -> ${expectedValue}")
                $item.SetAttributeValue($attrName, $expectedValue)
                $save = $true
            }
        }

        foreach ($attr in $item.Attributes)
        {
            if ($InputObject.Contains($attr.Name))
            {
                continue
            }

            [void]$msgs.Add("    - $($attr.Name)")
            [void]$attr.Delete()
            $save = $true
        }
    }

    end
    {
        if ($save)
        {
            foreach ($msg in $msgs)
            {
                Write-Information $msg
            }

            if ($SkipCommit)
            {
                return $true
            }
            else
            {
                Save-CIisConfiguration
            }
        }
    }
}