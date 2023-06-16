function Get-CIisCollectionKeyName
{
    <#
    .SYNOPSIS
    Returns the unique key for the child elements of the provided `Microsoft.Web.Administration.ConfigurationElementCollection`

    .DESCRIPTION
    The `Get-CIisCollectionKeyName` function finds the required unique key for the provided
    `Microsoft.Web.Administration.ConfigurationElementCollection`. The unique key changes depending on the collection
    passed into the function.

    .EXAMPLE
    Get-CIisCollectionKeyName -Collection (Get-CIisCollection -SectionPath 'system.webServer/httpProtocol' -Name 'customHeaders')

    Demonstrates how to get the collection key name for the 'system.webServer/httpProtocol/customHeaders' collection.
    This will return 'name' as the key name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ConfigurationElementCollection] $Collection
    )
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return $Collection.CreateElement().Attributes |
        Where-Object { $_.Schema.IsUniqueKey } |
        Select-Object -ExpandProperty 'name'
}