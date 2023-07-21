function Set-CIisCollection
{
    <#
    .SYNOPSIS
    Sets the exact contents of an IIS configuration section collection.

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

        $collectionArgs = @{}

        if ($LocationPath)
        {
            $collectionArgs['LocationPath'] = $LocationPath
        }

        if ($Name)
        {
            $collectionArgs['Name'] = $Name
        }

        $errorThrown = $false

        $collection = Get-CIisCollection -SectionPath $SectionPath @collectionArgs

        $pathMessage = "$($LocationPath):$($SectionPath)"

        if ($Name)
        {
            $pathMessage = "$($pathMessage)/$($Name)"
        }

        if (-not $collection)
        {
            $errorThrown = $true
            return
        }

        $keyAttrName = Get-CIisCollectionKeyName -Collection $collection

        if (-not $keyAttrName)
        {
            $msg = "Unable to find key for $($pathMessage)"
            Write-Error -Message $msg
            $errorThrown = $true
            return
        }

        $save = $false
    }
    process
    {
        if ($errorThrown)
        {
            return
        }

        foreach ($item in $InputObject)
        {
            $addItem = $collection.CreateElement('add')
            if ($item -is [string])
            {
                $addItem.SetAttributeValue($keyAttrName, $item)
            }
            elseif ($item -is [hashtable])
            {
                foreach ($key in $item.Keys)
                {
                    $addItem.SetAttributeValue($key, $item[$key])
                }
            }
            else
            {
                $msg = "Was expecting the input to be a string or a hashtable but got $($item.GetType())"
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            }
            $items.Add($addItem)
        }
    }
    end
    {
        if ($errorThrown)
        {
            return
        }
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
