function Remove-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Removes a IIS Configuration element.

    .DESCRIPTION
    The `Remove-CIisCollectionItem` function removes an item from an IIS configuration collection. Pass the collection's
    IIS configuration section path to the `SectionPath` parameter and the value to remove from the collection to the
    `Value` parameter. This function removes that value from the collection if it exists.

    If removing an item from the collection for a website, application, virtual directory, pass the path to that
    location to the `LocationPath` parameter'

    .EXAMPLE
    Remove-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove the 'X-CarbonRemoveItem' header if it has previously been added.

    .EXAMPLE
    Remove-CIisCollectionItem -LocationPath 'SITE_NAME' -SectionPath `system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove the 'X-CarbonRemoveItem' header from the 'SITE_NAME' location.
    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        # The site name where the item should be removed.
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $LocationPath,

        # The path to the section the item is located.
        [Parameter(Mandatory)]
        [String] $SectionPath,

        # The collection the item belongs to.
        [String] $CollectionName,

        # The value to be removed.
        [Parameter(Mandatory)]
        [Object] $Value
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $collectionArgs = @{}

    if ($LocationPath)
    {
        $collectionArgs['LocationPath'] = $LocationPath
    }
    if ($CollectionName)
    {
        $collectionArgs['Name'] = $CollectionName
    }

    $collection = Get-CIisCollection @collectionArgs -SectionPath $SectionPath

    $keyAttrName = Get-CIisCollectionKeyName -Collection $collection

    $itemToRemove = $collection | Where-Object { $_.GetAttributeValue($keyAttrName) -eq $Value }

    if ($CollectionName)
    {
        $outputSection = "$($SectionPath)/$($CollectionName)"
    }
    else
    {
        $outputSection = "$($SectionPath)"
    }

    if (-not $itemToRemove)
    {
        $msg = "Unable to find item ""$($Value)"" in ""$($LocationPath):$($outputSection)"""
        Write-Error $msg -ErrorAction $ErrorActionPreference
        return
    }

    $collection.Remove($itemToRemove)
    Write-Information "IIS $($LocationPath):$($outputSection)"
    Write-Information "    - $($Value)"
    Save-CIisConfiguration
}