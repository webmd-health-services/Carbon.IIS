function Get-CIisCollection
{
    <#
    .SYNOPSIS
    Gets an instance of an IIS Collection

    .DESCRIPTION
    The `Get-CIisCollection` function gets the specified IIS collection. Pass the collection's IIS confuguration section
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
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        # The name of the site where the collection belongs
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $LocationPath,

        # The path for the configuration section that points to the collection
        [Parameter(Mandatory)]
        [String] $SectionPath,

        # The name of the collection
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getArgs = @{}

    if ($LocationPath)
    {
        $getArgs['LocationPath'] = $LocationPath
    }

    $section = Get-CIisConfigurationSection @getArgs -SectionPath $sectionPath

    if ($Name)
    {
        $collection = $section.GetCollection($Name)
    }
    else
    {
        $collection = $section.GetCollection()
    }

    if (-not $collection)
    {
        if ($Name)
        {
            $msg = "IIS:$($LocationPath): configuration path $($SectionPath)/$($Name) is not a collection."
        }
        else
        {
            $msg = "IIS:$($LocationPath): configuration path $($SectionPath) is not a collection."
        }

        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    if ($Name -and $collection.ElementTagName -ne $Name)
    {
        $msg = "IIS:$($LocationPath): configuration path $($SectionPath) with collection name $($Name) had the wrong " +
               "element name."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    return ,$collection
}