function Set-CIisCollection
{
    <#
    .SYNOPSIS
    Changes the specied IIS Collection to only contain provided elements.

    .DESCRIPTION
    The `Set-CIisCollection` function adds the provided elements to the specified IIS configuration collection. If a
    `LocationPath` is set, then the function will clear all existing elements, otherwise it will just add to the
    existing element list and leave the pre-set global values. The provided `$InputObjects` can be either hashtables or
    strings. If they are hashtables then `Set-CIisCollection` will create elements with attributes that match all of the
    key value pairs. If they are strings, then the function will use the strings to set th attribute for the collection's unique key values.

    .EXAMPLE
    @{ name = 'HttpLoggingModule' ; image = '%windir%\System32\inetsrv\loghttp.dll' } | Set-CIisCollection -SectionPath 'system.webServer/globalModules'

    Demonstrates how to set a collection to a specific list where each item in the collection has more than a single
    default attribute. The above command would result in the applicationHost.config file to be updated to be:

        <system.webServer>
            <globalModules>
                <add name="HttpLoggingModule" image="%windir%\System32\inetsrv\loghttp.dll" />
            </globalModules>
        </system.webServer>

    .EXAMPLE
    'default.aspx', 'index.html' | Set-CIisCollection -LocationPath 'SITE_NAME' -SectionPath 'system.webServer/defaultDocument' -Name 'files'

    Demonstrates how to set an IIS collection to have only a specific list of values by piping them to the function.
    After the above command runs, this will be in the applicationHost.config:

        <location path="SITE_NAME">
            <system.webServer>
                <defaultDocument>
                    <files>
                        <clear />
                        <add value="default.aspx" />
                        <add value="index.html" />
                    </files>
                </defaultDocument>
            </system.webServer>
        </location>

    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        # The site the collection belongs to.
        [Parameter(Mandatory, ParameterSetName='Location')]
        [String] $LocationPath,


        # The path to the collection.
        [Parameter(Mandatory)]
        [String] $SectionPath,

        # The name of the collection to change.
        [String] $Name,

        # Pass a hashtable for each item that has more than one attribute value to set. Otherwise, pass the attribute
        # value for the default attribute.
        [Parameter(ValueFromPipeline)]
        [Object[]] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
        $items = [Collections.Generic.List[Microsoft.Web.Administration.ConfigurationElement]]::New()
        $collection = Get-CIisCollection @PSBoundParameters
        $keyAttrName = Get-CIisCollectionKeyName -Collection $collection
        $save = $false
    }

    process
    {
        $addItem = $collection.CreateElement('add')
        if ($InputObject[0] -is [string])
        {
            $addItem.SetAttributeValue($keyAttrName, $InputObject[0])
        }
        elseif ($InputObject[0] -is [hashtable])
        {
            foreach ($key in $InputObject[0].Keys)
            {
                $addItem.SetAttributeValue($key, $InputObject[0][$key])
            }
        }
        else
        {
            $msg = "Was expecting the input to be a string or a hashtable but got $($InputObject[0].GetType())"
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }
        $items.Add($addItem)
    }
    end
    {
        foreach ($collectionItem in $collection)
        {
            if ($collectionItem -notin $items)
            {
                $collection.Clear()
                $save = $true
                break
            }
        }

        foreach ($item in $items)
        {
            $collection.Add($item)
        }

        if ($save)
        {
            Save-CIisConfiguration
        }
    }
}
