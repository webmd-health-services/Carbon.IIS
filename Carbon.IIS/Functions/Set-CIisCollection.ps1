function Set-CIisCollection
{
    <#
    .SYNOPSIS
    Sets the exact contents of an IIS configuration section collection.

    .DESCRIPTION
    The `Set-CIisCollection` function sets IIS configuration collection to a specific set of items. Pipe the collection
    items to the function (or pass them to the `InputObject` parameter). You can pass just item vales if the collection
    items only have single values. Otherwise, pass a hashtable of name/value pairs.

    To make changes to a global configuration section, pass its path to the `SectionPath` parameter. To make changes to
    a site, directory, application, or virtual directory, pass its pass location path to the `LocatinPath`. To make
    changes to a specifci `[Microsoft.Web.Administration.ConfigurationElement]` object, pass it to the
    `ConfigurationElement` parameter.

    When making changes directly to ConfigurationElement objects, test that those changes are saved correctly to the IIS
    application host configuration. Some configuration has to be saved at the same time as its parent configuration
    elements are created (i.e. sites, application pools, etc.). Use the `Suspend-CIisAutoCommit` and
    `Resume-CIisAutoCommit` functions to ensure configuration gets committed simultaneously.

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
    [CmdletBinding()]
    param(
        # The configuration element on which to operate. If not a collection, pass the name of the collection under this
        # element to the `Name` parameter.
        [Parameter(Mandatory, ParameterSetName='ByConfigurationElement')]
        [ConfigurationElement] $ConfigurationElement,

        # The path to the collection.
        [Parameter(Mandatory, ParameterSetName='ByPath')]
        [String] $SectionPath,

        # The site the collection belongs to.
        [Parameter(ParameterSetName='ByPath')]
        [String] $LocationPath,

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

        function Write-Message
        {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [AllowNull()]
                [AllowEmptyString()]
                [String] $Message
            )

            process
            {
                if (-not $firstLineWritten)
                {
                    Write-Information "Setting IIS configuration collection ${displayPath}."
                    $firstLineWritten = $true
                }

                Write-Information "    ${Message}"
            }
        }

        $stopProcessing = $false
        $firstLineWritten = $false

        $getSetArgs = @{}
        if ($Name)
        {
            $getSetArgs['Name'] = $Name
        }

        $displayPath = ''
        if ($ConfigurationElement)
        {
            $getSetArgs['ConfigurationElement'] = $ConfigurationElement
            $displayPath = $ConfigurationElement.ElementTagName
        }
        else
        {
            $getSetArgs['SectionPath'] = $SectionPath

            if ($LocationPath)
            {
                $getSetArgs['LocationPath'] = $LocationPath
            }

            $displayPath =
                Get-CIisDisplayPath -SectionPath $SectionPath -LocationPath $LocationPath -SubSectionPath $Name
        }

        $collection = Get-CIisCollection @getSetArgs

        if (-not $collection)
        {
            $stopProcessing = $true
            return
        }

        $items = [List[hashtable]]::New()
        $keyValues = @{}
        $keyAttrName = Get-CIisCollectionKeyName -Collection $collection

        if (-not $keyAttrName)
        {
            $msg = "Failed to set IIS configuration collection ${displayPath} because it does not have a key attribute."
            Write-Error -Message $msg
            $stopProcessing = $true
            return
        }
    }

    process
    {
        if ($stopProcessing)
        {
            return
        }

        foreach ($item in $InputObject)
        {
            if ($item -isnot [IDictionary])
            {
                $item = @{ $keyAttrName = $item }
            }

            $items.Add($item)
            $keyValues[$item[$keyAttrName]] = $true
        }
    }

    end
    {
        if ($stopProcessing)
        {
            return
        }

        $itemsToRemove =
            $collection |
            ForEach-Object { $_.GetAttributeValue($keyAttrName) } |
            Where-Object { -not $keyValues.ContainsKey($_) }

        $itemsRemoved = $itemsToRemove | Remove-CIisCollectionItem @getSetArgs -SkipCommit

        $itemsModified = $items | Set-CIisCollectionItem @getSetArgs -SkipCommit

        if ($itemsRemoved -or $itemsModified)
        {
            Save-CIisConfiguration
        }
    }
}
