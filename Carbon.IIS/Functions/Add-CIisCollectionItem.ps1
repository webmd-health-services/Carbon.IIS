function Add-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Adds a new `Microsoft.Web.Administration.ConfigurationElement` with the add element name to a collection.

    .DESCRIPTION
    The `Add-CIisCollectionItem` function adds a new `<add />` configuration element with the default key provided as the `$Value` parameter.
    This function can also add additional fields using the `$Attribute` paramater as long as the unique key is provided in the hashtable.
    After adding an item, the changes to applicationHost.config are committed and saved automatically.

    .EXAMPLE
    Add-CIisCollectionItem -LocationPath 'SITE_NAME' -SectionPath 'system.webServer/defaultDocument' -CollectionName 'files' -Value 'hello.htm'

    Demonstrates how to add an item in an IIS collection with the provided value.
    After the above command runs, this will be in the applicationHost.config:

        <location path="SITE_NAME">
            <system.webServer>
                <defaultDocument>
                    <files>
                        <add value="hello.htm" />
                    </files>
                </defaultDocument>
            </system.webServer>
        </location>

    .EXAMPLE
    Add-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders' -Attribute @{ 'name' = 'foo'; 'value' = 'bar' }

    Demonstrates how to add an item in an IIS collection with the provided attriute hashtable.
    After the above command runs, this will be in the applicationHost.config:

        <system.webServer>
            <httpProtocol>
                <customHeaders>
                    <add name='foo' value='bar' />
                </customHeaders>
            </httpProtocol>
        </system.webServer>

    #>
    [CmdletBinding(DefaultParameterSetName='GlobalBySingleKey')]
    param(
        [Parameter(Mandatory, ParameterSetName='Location')]
        [Parameter(Mandatory, ParameterSetName='LocationBySingleKey')]
        [Parameter(Mandatory, ParameterSetName='LocationByAllAttributes')]
        [String] $LocationPath,

        [Parameter(Mandatory)]
        [String] $SectionPath,

        [String] $CollectionName,

        [Parameter(Mandatory, ParameterSetName='LocationBySingleKey')]
        [Parameter(Mandatory, ParameterSetName='GlobalBySingleKey')]
        [AllowNull()]
        [Object] $Value,

        [Parameter(Mandatory, ParameterSetName='GlobalByAllAttributes')]
        [Parameter(Mandatory, ParameterSetName='LocationByAllAttributes')]
        [AllowNull()]
        [hashtable] $Attribute
    )
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $save = $false

    $collectionArgs = @{
        'SectionPath' = $SectionPath
    }

    if ($LocationPath)
    {
        $collectionArgs['LocationPath'] = $LocationPath
    }

    if ($CollectionName)
    {
        $collectionArgs['Name'] = $CollectionName
    }

    $collection= Get-CIisCollection @collectionArgs

    $uniqueKeyAttrName = Get-CIisCollectionKeyName -Collection $collection

    if (-not $Value)
    {
        if ($Attribute -and $Attribute[$uniqueKeyAttrName])
        {
            $Value = $Attribute[$uniqueKeyAttrName]
        }
        else
        {
            $msg = "Unable to add item to ""$($LocationPath)/$($SectionPath)/$($CollectionName)"" because the " +
                   "unique key for the collection ""$($uniqueKeyAttrName)"" was not found in the Attribute parameter " +
                   "hashtable. Please add an entry for the unique key or use the Value parameter."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }
    }

    $existingElement = $collection |
                Where-Object { $_.GetAttributeValue($uniqueKeyAttrName) -eq $Value }

    $msgPrefix = "IIS section $($LocationPath)/$($SectionPath)/$($CollectionName)"

    if (-not $existingElement)
    {
        $add = $collection.CreateElement('add')
        if ($Attribute)
        {
            $msgContent = [System.Collections.ArrayList]@()
            foreach ($attributeKey in $Attribute.Keys)
            {
                $add.SetAttributeValue($attributeKey, $Attribute[$attributeKey])
                $msgContent.Add("$($uniqueKeyAttrName): $($Value)")
            }
            Write-Information "$($msgPrefix)  + $($msgContent -Join ',')"
        }
        else
        {
            $add.SetAttributeValue($uniqueKeyAttrName, $Value)
            Write-Information "$($msgPrefix)  + $($uniqueKeyAttrName): $($Value)"
        }
        [void]$collection.Add($add)
        $save = $true
    }
    elseif ($Attribute)
    {
        $msgContent = [System.Collections.ArrayList]@()
        foreach ($attributeKey in $Attribute.Keys)
        {
            $attributeVal = $Attribute[$attributeKey]
            $existingVal = $existingElement.GetAttributeValue($attributeKey)
            if ($existingVal -ne $attributeVal)
            {
                $msgContent.Add("$($existingVal) -> $($attributeVal)")
                $existingElement.SetAttributeValue($attributeKey, $attributeVal)
                $save = $true
            }
        }

        if ($save)
        {
            Write-Information "$($msgPrefix)  + $($msgContent -Join ',')"
        }
    }

    if ($save)
    {
        Save-CIisConfiguration
    }
}