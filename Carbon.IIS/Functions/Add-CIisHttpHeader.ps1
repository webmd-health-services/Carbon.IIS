function Add-CIisHttpHeader
{
    <#
    .SYNOPSIS
    Adds a new 'customHeader' configuration element in the 'system.webServer/httpProtocol' collection.

    .DESCRIPTION
    The `Add-CIisHttpHeader` function adds a new `<add />` element to the 'system.webServer/httpProtocol/customHeaders'
    collection with the provided name and value attributes. If an item already exists in the collection with the provided
    name attribute, the previous value will be overwritten with the new attribute.

    .EXAMPLE
    Add-CIisHttpHeader -Name 'foo' -Value 'bar'

    Demonstrates how to add an item to the 'system.webServer/httpProtocol/customHeaders' collection
    with the provided name and value. After the above command runs, this will be in the applicationHast.config:

        <system.webServer>
            <httpProtocol>
                <customHeaders>
                    <add name="foo" value="bar" />
                </customHeaders>
            </httpProtocol>
        </system.webServer>

    .EXAMPLE
    Add-CIisHttpHeader -LocationPath 'SITE_NAME' -Name 'X-AddHeader' -Value 'usingCarbon'

    Demonstrates how to add an item to the 'customHeaders' IIS collection with a specific Location Path.
    After the above command runs. this will be in the applicationHost.config:

        <location path="SITE_NAME">
            <system.webServer>
                <httpProtocol>
                    <customHeaders>
                        <add name="foo" value="bar" />
                    </customHeaders>
                </httpProtocol>
            </system.webServer>
        <location path="SITE_NAME" />
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Name,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Value,

        [String] $LocationPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $attributes = @{
        'name' = $Name
        'value' = $Value
    }

    $addParameters = @{
        'SectionPath' = 'system.webServer/httpProtocol'
        'CollectionName' = 'customHeaders'
    }

    if ($LocationPath)
    {
        $addParameters['LocationPath'] = $LocationPath
    }

    Add-CIisCollectionItem @addParameters -Attribute $attributes
}