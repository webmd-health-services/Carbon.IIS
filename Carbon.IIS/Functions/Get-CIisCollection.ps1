function Get-CIisCollection
{
    <#
    .SYNOPSIS
    Gets an IIS configuration ollection.

    .DESCRIPTION
    The `Get-CIisCollection` function gets an IIS configuration element as a collection. Pass the collection's IIS
    configuration section path to the `SectionPath` parameter. If the collection is actually a child element of the
    configuration section, pass the name of the child element collection to the `Name` parameter. To get the section for
    a specific site, directory, application, or virtual directory, pass its location path to the `LocationPath`
    parameter.

    You can pass an instance of a `[Microsoft.Web.Administration.ConfigurationElement]` to the `ConfigurationElement`
    parameter to return that element as a collection, or, with the `Name` parameter, get a named collection under that
    configuration element.

    This function returns a configuration element collection object. To get the items from the collection, use
    `Get-CIisCollectionItem`.

    .EXAMPLE
    $collection = Get-CIisCollection -LocationPath 'SITE_NAME' -SectionPath 'system.webServer/httpProtocol/' -Name 'customHeaders'

    Demonstrates how to get the collection 'customHeaders' inside the section 'system.webServer/httpProtocol' for the
    site 'SITE_NAME'.
    #>
    [CmdletBinding()]
    param(
        # The `[Microsoft.Web.Administration.ConfigurationElement]` object to get as a collection or the parent element
        # of the collection element to get. If this is the parent element, pass the name of the child element collection
        # to the `CollectionName` parameter.
        [Parameter(Mandatory, ParameterSetName='Direct')]
        [ConfigurationElement] $ConfigurationElement,

        # The configuration section path of the collection, or, if the configuration section is a parent of the
        # collection, the configuration section path to the parent configuration section. If the configuration section
        # is the parent of the collection, pass the collection name to the `CollectionName` parameter.
        [Parameter(Mandatory, ParameterSetName='ByPath')]
        [String] $SectionPath,

        # The location path to the site, directory, application, or virtual directory to configure.
        [Parameter(ParameterSetName='ByPath')]
        [String] $LocationPath,

        # The collection's name.
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $displayPath = ''
    if ($ConfigurationElement)
    {
        $displayPath = $ConfigurationElement.ElementTagName
    }
    else
    {
        $getArgs = @{}
        if ($LocationPath)
        {
            $getArgs['LocationPath'] = $LocationPath
        }

        $ConfigurationElement = Get-CIisConfigurationSection @getArgs -SectionPath $SectionPath
        if (-not $ConfigurationElement)
        {
            return
        }

        $displayPath = Get-CIisDisplayPath -SectionPath $SectionPath -LocationPath $LocationPath -SubSectionPath $Name
    }

    if ($Name)
    {
        $collection = $ConfigurationElement.GetCollection($Name)
    }
    elseif ($ConfigurationElement -is [ICollection])
    {
        $collection = $ConfigurationElement
    }
    else
    {
        $collection = $ConfigurationElement.GetCollection()
    }

    if (-not $collection)
    {
        $msg = "Failed to get IIS configuration collection ${displayPath} because it does not exist or is not a " +
               'collection'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return ,$collection
}