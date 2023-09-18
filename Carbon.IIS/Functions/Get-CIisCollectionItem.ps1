function Get-CIisCollectionItem
{
    <#
    .SYNOPSIS
    Gets the items from an IIS configuration collection.

    .DESCRIPTION
    The `Get-CIisCollectionItem` function gets the items from an IIS configuration element collection. Pass the
    collection's IIS configuration section path to the `SectionPath` parameter. If the configuration section is actually
    the parent element of the the collection, pass the name of the child element collection to the `CollectionName`
    parameter. To get the section for a specific site, directory, application, or virtual directory, pass its location
    path to the `LocationPath` parameter.

    You can pass an instance of a `[Microsoft.Web.Administration.ConfigurationElement]` to the `ConfigurationElement`
    parameter to return that collection element's items, or, with the `CollectionName` parameter, get a named collection
    under that configuration element.

    This function returns configuration element collection items. To get the collection object itself, use
    `Get-CIisCollection`.


    .EXAMPLE
    $items = Get-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' -CollectionName 'customHeaders'

    Demonstrates how to get the custom HTTP headers from the 'customHeaders' collection, which is a child of the
    "system.webServer/httpProtocol" configuration section.
    #>
    [CmdletBinding(DefaultParameterSetName='BySectionPath')]
    param(
        # The `[Microsoft.Web.Administration.ConfigurationElement]` object whose collection items to get, or the parent
        # element of the collection whose items to get. If this is the parent element, pass the name of the child
        # element collection to the `CollectionName` parameter.
        [Parameter(Mandatory, ParameterSetName='ByConfigurationElement')]
        [ConfigurationElement] $ConfigurationElement,

        # The configuration section path of the collection, or, if the configuration section is a parent of the
        # collection, the configuration section path to the parent configuration section. If the configuration section
        # is the parent of the collection, pass the collection name to the `CollectionName` parameter.
        [Parameter(Mandatory, ParameterSetName='BySectionPath')]
        [String] $SectionPath,

        # The location path to the site, directory, application, or virtual directory to configure.
        [Parameter(ParameterSetName='BySectionPath')]
        [String] $LocationPath,

        # The collection's name.
        [Alias('Name')]
        [String] $CollectionName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSBoundParameters.ContainsKey('CollectionName'))
    {
        $PSBoundParameters['Name'] = $CollectionName
        $PSBoundParameters.Remove('CollectionName') | Out-Null
    }

    Get-CIisCollection @PSBoundParameters | Write-Output
}