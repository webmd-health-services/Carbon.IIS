
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
        # The configuration element who's inheritance to disable. Can be the collection itself, or the collection's
        # parent element. If passing the parent element, pass the name of the collection to the `Name` parameter.
        [Parameter(Mandatory)]
        [String] $SectionPath,

        # Location path to the site, directory, application, or virtual directory that should be changed. The default is
        # to modify global configuration.
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

        $displayPath = Get-CIisDisplayPath -SectionPath $sectionPath -LocationPath $LocationPath
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