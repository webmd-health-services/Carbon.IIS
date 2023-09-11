
function Disable-CIisCollectionInheritance
{
    <#
    .SYNOPSIS
    Updates IIS configuration collections so they no longer inherit items.

    .DESCRIPTION
    The `Disable-CIisCollectionInheritance` function turns off inheritance of items in an IIS configuration collection,
    i.e. it adds a `<clear />` element to the collection. Pass the path to the configuration section collection to the
    `SectionPath` parameter. If the collection is actually a sub-element of the configuration section, pass the name of
    the collection to the `Name` parameter. Inheritance is disabled only if the collection doesn't already have a
    `<clear />` element. The function reads the applicationHost.config in order to make this determination, since there
    are no APIs that make this information available.

    To disable inheritance for a site, directory, application, or virtual directory, pass its location path to the
    `LocationPath` parameter.

    To disable inheritance for a collection that is a or is a child of a
    `[Microsoft.Web.Administration.ConfigurationElement]` (i.e. configuration under a site, application pool, etc.),
    pass the object to the `ConfigurationElement` parameter. If the object isn't a collection, pass the name of the
    child element collection to the `Name` parameter.

    When making changes directly to ConfigurationElement objects, test that those changes are saved correctly to the IIS
    application host configuration. Some configuration has to be saved at the same time as its parent configuration
    elements are created (i.e. sites, application pools, etc.). Use the `Suspend-CIisAutoCommit` and
    `Resume-CIisAutoCommit` functions to ensure configuration gets committed simultaneously.

    .EXAMPLE
    Disable-CIisCollectionInheritance -SectionPath 'system.webServer/httpProtocol' -Name 'customHeaders'

    Demonstrates how to disable inheritance on a global collection by passing its configuration section path to the
    `SectionPath` parameter and the collection name to the `Name` parameter.

    .EXAMPLE
    Disable-CIisCollectionInheritance -SectionPath 'system.webServer/httpProtocol' -Name 'customHeaders' -LocationPath 'mysite'

    Demonstrates how to disable inheritance on a collection under a site, directory, application, or virtual directory
    by passing the location path to the site, directory, application, or vitual directory to the `LocationPath`
    parameer.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='ByConfigurationElement')]
        [ConfigurationElement] $ConfigurationElement,

        # The configuration section's path who's inheritance to disable. Can be the path to the collection itself, or
        # the collection's parent element. If passing the parent element, pass the name of the collection to the `Name`
        # parameter.
        [Parameter(Mandatory, ParameterSetName='ByPath')]
        [String] $SectionPath,

        # Location path to the site, directory, application, or virtual directory that should be changed. The default is
        # to modify global configuration.
        [Parameter(, ParameterSetName='ByPath')]
        [String] $LocationPath,

        # The name of the collection.
        [String] $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $collection = Get-CIisCollection @PSBoundParameters
        if (-not $collection)
        {
            return
        }

        $displayPath = $collection.ElementTagName
        if ($PSCmdlet.ParameterSetName -eq 'ByPath')
        {
            $displayPath = Get-CIisDisplayPath -SectionPath $sectionPath -LocationPath $LocationPath
        }

        if (-not $collection.AllowsClear)
        {
            $msg = "Failed to clear collection ${displayPath} because it does not allow clearing."
            Write-Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $xpath = $SectionPath.Trim('/')
        if ($Name)
        {
            $xpath = "${xpath}/$($Name.Trim('/'))"
        }

        # The Microsoft.Web.Administration API does not expose any way of determining if a collection has a `clear`
        # element, so we have to crack open the applicationHost.config file to look for it. :(
        if (Test-CIisApplicationHostElement -XPath "${xpath}/clear" -LocationPath $LocationPath)
        {
            return
        }

        Write-Information "Disabling IIS collection inheritance for ${displayPath}."
        $collection.Clear()

        Save-CIisConfiguration
    }
}