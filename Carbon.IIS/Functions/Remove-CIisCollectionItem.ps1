function Remove-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Removes a IIS configuration element.

    .DESCRIPTION
    The `Remove-CIisCollectionItem` function removes an item from an IIS configuration collection. Pass the collection's
    IIS configuration section path to the `SectionPath` parameter and the value to remove from the collection to the
    `Value` parameter. This function removes that value from the collection if it exists. If the value does not exist,
    the function writes an error.

    If removing an item from the collection for a website, application, virtual directory, pass the path to that
    location to the `LocationPath` parameter'

    .EXAMPLE
    Remove-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove the 'X-CarbonRemoveItem' header if it has previously been added.

    .EXAMPLE
    Remove-CIisCollectionItem -LocationPath 'SITE_NAME' -SectionPath `system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove the 'X-CarbonRemoveItem' header from the 'SITE_NAME' location.
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

        # The location path of the site, directory, application, or virtual directory whose configuration to update.
        # Default is to update the global configuration.
        [Parameter(ParameterSetName='BySectionPath')]
        [String] $LocationPath,

        # The collection the item belongs to.
        [Alias('Name')]
        [String] $CollectionName,

        # The value to be removed.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]] $Value,

        # The attribute name for the attribute that uniquely identifies each item in a collection. This is usually
        # automatically detected.
        [String] $UniqueKeyAttributeName,

        # ***INTERNAL***. Do not use.
        [switch] $SkipCommit
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $getArgs = @{}
        if ($CollectionName)
        {
            $getArgs['Name'] = $CollectionName
        }

        $displayPath = ''
        if ($ConfigurationElement)
        {
            $getArgs['ConfigurationElement'] = $ConfigurationElement
            $displayPath = $ConfigurationElement.ElementTagName
        }
        else
        {
            $getArgs['SectionPath'] = $SectionPath
            if ($LocationPath)
            {
                $getArgs['LocationPath'] = $LocationPath
            }
            $displayPath =
                Get-CIisDisplayPath -SectionPath $SectionPath -LocationPath $LocationPath -SubSectionPath $CollectionName
        }

        $stopProcessing = $false

        $collection = Get-CIisCollection @getArgs
        if (-not $collection)
        {
            $stopProcessing = $true
            return
        }

        if (-not $UniqueKeyAttributeName)
        {
            $UniqueKeyAttributeName = Get-CIisCollectionKeyName -Collection $collection

            if (-not $UniqueKeyAttributeName)
            {
                $stopProcessing = $true
                $msg = "Failed to remove items from IIS configuration collection ${displayPath} because that " +
                       'collection doesn''t have a unique key attribute. Use the "UniqueKeyAttributeName" parameter ' +
                       'to specify the attribute name.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }
        }

        $firstLine = "IIS configuration collection ${displayPath}"
        $firstLineWritten = $false

        $itemsRemoved = $false
    }

    process
    {
        if ($stopProcessing)
        {
            return
        }

        foreach ($valueItem in $Value)
        {
            $itemToRemove = $collection | Where-Object { $_.GetAttributeValue($UniqueKeyAttributeName) -eq $valueItem }

            if (-not $itemToRemove)
            {
                $msg = "Failed to remove item ""${valueItem}"" from IIS configuration collection ${displayPath} " +
                       'because it doesn''t exist in the collection.'
                Write-Error $msg -ErrorAction $ErrorActionPreference
                return
            }

            if (-not $firstLineWritten)
            {
                Write-Information $firstLine
                $firstLineWritten = $true
            }

            Write-Information "  - $($valueItem)"
            $collection.Remove($itemToRemove)
            $itemsRemoved = $true
        }
    }

    end
    {
        if ($stopProcessing -or -not $itemsRemoved)
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