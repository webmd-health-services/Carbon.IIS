function Add-CIisHttpHeader
{
    <#
    .SYNOPSIS
    Adds a new HTTP header to IIS.

    .DESCRIPTION
    The `Add-CIisHttpHeader` function adds a new header to the IIS configuration. Pass the header's name to the `Name`
    parameter and the header's value to the `Value` parameter. By default, the header is added to all HTTP responses. To
    add the header only to responses from a specific website, application, virtual directory, or directory, pass the
    path to that location to the `LocationPath` parameter.

    The function adds the HTTP header by adding it to the `system.webServvver/httpProtocol/customHeaders` configuration
    collection.

    .EXAMPLE
    Add-CIisHttpHeader -Name 'foo' -Value 'bar'

    Demonstrates how to add a new HTTP header globally. After the above command runs, this will be in the applicationHost.

        <system.webServer>
            <httpProtocol>
                <customHeaders>
                    <add name="foo" value="bar" />
                </customHeaders>
            </httpProtocol>
        </system.webServer>

    .EXAMPLE
    Add-CIisHttpHeader -LocationPath 'SITE_NAME' -Name 'X-AddHeader' -Value 'usingCarbon'

    Demonstrates how to add a new HTTP header to the site `SITE_NAME`. After the above command runs, this will be in:
    the applicationHost.config:

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
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        # The HTTP header name to add
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Name,

        # The HTTP header value to add
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Value,

        # The sitename to edit
        [Parameter(ParameterSetName='Local')]
        [String] $LocationPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $setConditionalArgs = @{}

    if ($LocationPath)
    {
        $setConditionalArgs['LocationPath'] = $LocationPath
    }

    Set-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' `
                           -CollectionName 'customHeaders' `
                           -Value $Name `
                           -Attribute @{ 'value' = $Value } `
                           @setConditionalArgs
}