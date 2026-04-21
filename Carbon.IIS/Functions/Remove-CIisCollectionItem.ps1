function Remove-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Removes a IIS configuration element.

    .DESCRIPTION
    The `Remove-CIisCollectionItem` function removes an item from an IIS configuration collection. Pass the collection's
    IIS configuration section path to the `SectionPath` parameter and the value to remove from the collection to the
    `Value` parameter. This function removes that value from the collection if it exists. If the value does not exist,
    the function writes an error. To remove collection items that might not exist without writing an error, use
    `Uninstall-CIisCollectionItem`.

    If removing an item from the collection for a website, application, virtual directory, pass the path to that
    location to the `LocationPath` parameter'

    .LINK
    Uninstal-CIisCollectionItem

    .EXAMPLE
    Remove-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove the 'X-CarbonRemoveItem' header if it has previously been added.

    .EXAMPLE
    Remove-CIisCollectionItem -LocationPath 'SITE_NAME' -SectionPath `system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove the 'X-CarbonRemoveItem' header from the 'SITE_NAME' location.

    .EXAMPLE
    'X-CarbonRemoveItem','X-CarbonRemoveItem2' | Remove-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders'

    Demonstrates that you can pipe the values to delete to `Remove-CIisCollectionItem`.
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
        # Default is to update the global configuration. When passing a configuration element, this parameter is only
        # used to log the location of the configuration element.
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
        $process = $true
    }

    process
    {
        if (-not $process)
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
                continue
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
        if (-not $process -or -not $itemsRemoved)
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