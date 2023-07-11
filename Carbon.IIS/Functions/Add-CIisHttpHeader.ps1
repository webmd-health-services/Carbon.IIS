function Add-CIisHttpHeader
{
    <#
    .SYNOPSIS
    Adds a new header to the IIS configuration.

    .DESCRIPTION
    The `Add-CIisHttpHeader` function adds a new header to the IIS configuration. If adding a header for a specific
    website, pass that location to the `LocationPath` parameter.

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

    $addParameters = @{}

    if ($LocationPath)
    {
        $addParameters['LocationPath'] = $LocationPath
    }

    Set-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' `
                           -CollectionName 'customHeaders' `
                           -Value $Name `
                           -Attribute @{ 'value' = $Value } `
                           @addParameters
}