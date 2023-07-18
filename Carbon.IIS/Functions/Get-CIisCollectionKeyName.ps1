function Get-CIisCollectionKeyName
{
    <#
    .SYNOPSIS
    Returns the unique key for a configuration collection.

    .DESCRIPTION
    The `Get-CIisCollectionKeyName` locates the mandatory attribute for an IIS configuration collection. This attribute
    name must be included for all entries inside of an IIS collection.

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