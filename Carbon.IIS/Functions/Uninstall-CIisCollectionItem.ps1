function Uninstall-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Removes an item from an IIS configuration collection, if it exists.

    .DESCRIPTION
    The `Uninstall-CIisCollectionItem` function removes an item from an IIS configuration collection, if the item
    exists. If the item doesn't exist, nothing happens. Pass the collection's IIS configuration section path to the
    `SectionPath` parameter and the value to remove from the collection to the `Value` parameter.

    If the configuration section isn't itself a collection, pass the name of the collection to the `CollectionName`
    parameter.

    If removing an item from the collection for a website, application, virtual directory, pass the path to that
    location to the `LocationPath` parameter'

    .EXAMPLE
    Uninstall-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove an item from a collection that is a subelement of a configuration section by passing the
    name of the collection to the `CollectionName` parameter. In this example, the `X-CarbonRemoveItem` headers is
    removed from the `system.webServer/httpProtocol` configuration section's `customHeaders` collection.

    .EXAMPLE
    Uninstall-CIisCollectionItem -LocationPath 'SITE_NAME' -SectionPath `system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove an item from a specific website, application, or virtual path by passing the path to that
    item to the `LocationPath` parameter. In this example, the `X-CarbonRemoveItem` headers is removed from the
    `system.webServer/httpProtocol` configuration section's `customHeaders` collection for the `SITE_NAME` website.

    .EXAMPLE
    'X-CarbonRemoveItem','X-CarbonRemoveItem2' | Uninstall-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders'

    Demonstrates that you can pipe the values to delete to `Uninstall-CIisCollectionItem`.
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
        # Default is to update the global configuration. When `ConfigurationElement` is used, this parameter is only
        # used in output messages.
        [String] $LocationPath,

        # The collection the item belongs to.
        [Alias('Name')]
        [String] $CollectionName,

        # The value to be removed.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]] $Value,

        # The attribute name for the attribute that uniquely identifies each item in a collection. This is usually
        # automatically detected.
        [String] $UniqueKeyAttributeName
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $process = $false

        $displayPath = Get-CIisDisplayPath -Argument $PSBoundParameters

        $collection = Get-CIisCollection -Argument $PSBoundParameters
        if (-not $collection)
        {
            return
        }

        if (-not $UniqueKeyAttributeName)
        {
            $UniqueKeyAttributeName = Get-CIisCollectionKeyName -Collection $collection
            if (-not $UniqueKeyAttributeName)
            {
                return
            }
        }

        $values = [Collections.Generic.List[String]]::New()
        $process = $true
    }

    process
    {
        if (-not $process)
        {
            return
        }

        foreach ($_value in $Value)
        {
            $itemToRemove = $collection | Where-Object { $_.GetAttributeValue($UniqueKeyAttributeName) -eq $_value }
            if (-not $itemToRemove)
            {
                $msg = "Skipping removing item ""${_value}"" from IIS configuration collection ${displayPath} " +
                       'because it doesn''t exist in the collection.'
                Write-Verbose $msg
                continue
            }

            $values.Add($_value)
        }
    }

    end
    {
        if ($values.Count)
        {
            $PSBoundParameters['Value'] = $values
            Remove-CIisCollectionItem @PSBoundParameters
        }
    }
}
