function Set-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Adds a new item to an IIS configuration collection.

    .DESCRIPTION
    The `Set-CIisCollectionItem` function adds a new item to an IIS configuration collection. Pass the collection's IIS
    configuration section path to the `SectionPath` parameter and the value to add to the collection to the `Value`
    parameter. The function adds that value to the collection if it doesn't already exist in the collection or if its
    value has changed.

    To add extra attributes to the collection item, pass the *extra* attributes as a hashtable to the `Attribute`
    parameter. If the item already exists in the collection, any attributes on the item that aren't in the `Attribute`
    hasthable are *removed* from the collection item.

    If the configuration section given by `SectionPath` isn't a collection, pass the name of the collection to the
    `CollectionName` parameter.

    If adding an item to the collection for a website, application, virtual directory, or directory, pass that path to
    that location to the `LocationPath` parameter.

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
        # The site to add the item to
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $LocationPath,

        # The path for the configuration section to edit
        [Parameter(Mandatory)]
        [String] $SectionPath,

        # The value for the IIS collection's identifying key.
        [Parameter(Mandatory)]
        [Object] $Value,

        # The name of the IIS collection to modify. If not provided, will use the SectionPath as the collection.
        [String] $CollectionName,

        # Additional attributes to be added to a new IIS item.
        [AllowNull()]
        [hashtable] $Attribute
    )
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $save = $false

    $msgs = [System.Collections.ArrayList] @()

    $collectionArgs = @{}

    $msgPrefix = 'IIS section '
    $outputSection = "$($LocationPath):$($SectionPath)"

    if ($LocationPath)
    {
        $msgPrefix = $msgPrefix + "$($LocationPath)/"
        $collectionArgs['LocationPath'] = $LocationPath
    }

    $msgPrefix = $msgPrefix + "$($SectionPath)"

    if ($CollectionName)
    {
        $msgPrefix = $msgPrefix + "/$($CollectionName)"
        $outputSection + "/$($CollectionName)"
        $collectionArgs['Name'] = $CollectionName
    }

    [void]$msgs.Add($msgPrefix)

    $collection = Get-CIisCollection @collectionArgs -SectionPath $SectionPath

    if (-not $collection)
    {
        return
    }

    $keyAttrName = Get-CIisCollectionKeyName -Collection $collection

    if (-not $keyAttrName)
    {
        $msg = "Unable to find key for $($outputSection)"
        Write-Error -Message $msg
        return
    }

    $add = $collection | Where-Object { $_.GetAttributeValue($keyAttrName) -eq $Value }

    if (-not $add)
    {
        $add = $collection.CreateElement('add')
        $add.SetAttributeValue($keyAttrName, $Value)
        [void]$collection.Add($add)
        [void]$msgs.Add("  + ${keyAttrName} = ${Value}")
        $save = $true
    }
    else
    {
        [void]$msgs.Add("    ${keyattrname} = ${value}")
    }

    if (-not $attribute)
    {
        $attribute = @{}
    }

    foreach ($attrname in $attribute.keys)
    {
        if ($attrname -eq $keyattrname)
        {
            $msg = "Pass walue with key ""$($attrname)"" as the Value parameter. Attribute is only for extra attributes"
            Write-Warning -Message $msg
            continue
        }

        $expectedValue = $attribute[$attrname]
        $actualValue = $add.getattributevalue($attrname)

        if ($null -eq $actualValue)
        {
            [void]$msgs.Add("      + ${attrname} = ${expectedValue}")
            $add.setattributevalue($attrname, $expectedValue)
            $save = $true
            continue
        }
        elseif ($expectedValue -ne $actualValue)
        {
            [void]$msgs.Add("      ${attrname}  $($actualValue) -> ${expectedValue}")
            $add.setattributevalue($attrname, $expectedValue)
            $save = $true
        }
    }

    foreach ($attr in $add.Attributes)
    {
        if ($attr.Name -eq $keyAttrName)
        {
            continue
        }

        if (-not $Attribute.containskey($attr.Name))
        {
            [void]$msgs.Add("    - $($attr.Name)")
            [void]$attr.delete()
            $save = $true
        }
    }

    if ($save)
    {
        foreach ($msg in $msgs)
        {
            Write-Information $msg
        }

        Save-CIisConfiguration
    }
}