function Get-CIisCollection
{
    <#
    .SYNOPSIS
    Returns an instance of a `Microsoft.Web.Administration.ConfigurationElementCollection` class.

    .DESCRIPTION
    The `Get-CIisCollection` function returns an instance of `Microsoft.Web.Aministration.ConfigurationElementCollection`
    class that is located at the provided `LocationPath`, `SectionPath`, and `Name`. If no name is provided then it
    returns the provided `SectionPath` as a `ConfigurationElementCollection` class.

    After using the configuration collection, if you've made any changes to any objects inside the collection, call the
    `Save-CIisConfiguration` function to save/commit your changes.

    .EXAMPLE
    $collection = Get-CIisCollection -SectionPath 'system.webServer/httpProtocol' -Name 'customHeaders'

    Demonstrates how to get the 'customHeaders' collection from the 'system.webServer/httpProtocol' section.
    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $LocationPath,

        [Parameter(Mandatory)]
        [String] $SectionPath,

        # If no name, call `GetCollection()` on the configuration element, passing no name.
        [String] $Name
    )

    $sectionArgs = @{
        "SectionPath" = $SectionPath
    }

    if ($LocationPath)
    {
        $sectionArgs["LocationPath"] = $LocationPath
    }

    $section = Get-CIisConfigurationSection @sectionArgs

    if ($Name)
    {
        return ,$section.GetCollection($Name)
    }
    return ,$section.GetCollection()
}