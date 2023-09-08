function Get-CIisCollection
{
    <#
    .SYNOPSIS
    Gets an instance of an IIS Collection

    .DESCRIPTION
    The `Get-CIisCollection` function gets the specified IIS collection. Pass the collection's IIS configuration section
    path to the `SectionPath` parameter.

    If the configuration section given by `SectionPath` is not a collection, pass the name of the collection to the
    `Name` parameter.

    If the collection needed is for a website, application, virtual directory, or directory, pass the path to that
    location to the `LocatianPath` parameter.

    .EXAMPLE
    $collection = Get-CIisCollection -LocationPath 'SITE_NAME' -SectionPath 'system.webServer/httpProtocol/' -Name 'customHeaders'

    Demonstrates how to get the collection 'customHeaders' inside the section 'system.webServer/httpProtocol' for the
    site 'SITE_NAME'.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='Direct')]
        [ConfigurationElement] $ConfigurationElement,

        # The path for the configuration section that points to the collection
        [Parameter(Mandatory, ParameterSetName='ByPath')]
        [String] $SectionPath,

        # The name of the site where the collection belongs
        [Parameter(ParameterSetName='ByPath')]
        [String] $LocationPath,

        # The name of the collection
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState


    if (-not $ConfigurationElement)
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
    }

    if ($Name)
    {
        $collection = $ConfigurationElement.GetCollection($Name)
    }
    else
    {
        $collection = $ConfigurationElement.GetCollection()
    }

    if (-not $collection)
    {
        $displayPath = Get-CIisDisplayPath -SectionPath $SectionPath -LocationPath $LocationPath -SubSectionPath $Name
        $msg = "Failed to get IIS configuration collection ${displayPath} because that it does not exist or is not a " +
               'collection'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return ,$collection
}