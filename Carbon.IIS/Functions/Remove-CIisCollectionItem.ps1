# Fails if what you're removing doesn't exist.
function Remove-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Removes a Configuration Element from the provided path with the Value provided.

    .DESCRIPTION
    The `Remove-CIisCollectionItem` function removes an `<add />` configuration element with the key provided as the `$Value` parameter.
    If no collection name is provided, then the function will modify the provided section.

    .EXAMPLE
    Remove-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders' -Value 'X-CarbonRemoveItem'

    Demonstrates how to remove the 'X-CarbonRemoveItem' header if it has previously been added.
    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $LocationPath,

        [Parameter(Mandatory)]
        [String] $SectionPath,

        # If no name, call `GetCollection()` on the configuration element, passing no name.
        [String] $CollectionName,

        [Parameter(Mandatory)]
        [String] $Value
    )
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

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

    $collection = Get-CIisCollection @collectionArgs

    $uniqueKeyAttrName = Get-CIisCollectionKeyName -Collection $collection

    $itemToRemove =
        $collection |
        Where-Object { $_.GetAttributeValue($uniqueKeyAttrName) -eq $Value }

    if (-not $itemToRemove)
    {
        $msg = "Unable to find item with key ""$($Value)"" in ""$($LocationPath)/$($SectionPath)/$($CollectionName)" +
               '".'
        Write-Warning $msg
        return
    }

    $msg = "Removing item with ""$($uniqueKeyAttrName)"": ""$($Value)"" from """ +
           "$($LocationPath)/$($SectionPath)/$($CollectionName)"""
    Write-Information $msg
    $collection.Remove($itemToRemove)
    Save-CIisConfiguration
}