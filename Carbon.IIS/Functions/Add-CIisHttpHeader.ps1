function Add-CIisHttpHeader
{
    <#
    .SYNOPSIS
    Adds an HTTP header to IIS.

    .DESCRIPTION
    The `Add-CIisHttpHeader` function adds a header to IIS. Pass the header's name to the `Name` parameter and the
    header's value to the `Value` parameter. By default, the header is added to all HTTP responses (i.e. IIS's global
    settings are updated). To add the header only to responses from a specific website, application, virtual directory,
    or directory, pass the location's path to the `LocationPath` parameter.

    The function adds the HTTP header to the `system.webServer/httpProtocol/customHeaders` configuration collection.

    .EXAMPLE
    Add-CIisHttpHeader -Name 'foo' -Value 'bar'

    Demonstrates how to add a new HTTP header globally. After the above command runs, this will be in the
    applicationHost.

        <system.webServer>
            <httpProtocol>
                <customHeaders>
                    <add name="foo" value="bar" />
                </customHeaders>
            </httpProtocol>
        </system.webServer>

    .EXAMPLE
    Add-CIisHttpHeader -LocationPath 'SITE_NAME' -Name 'X-AddHeader' -Value 'usingCarbon'

    Demonstrates how to add a new HTTP header to the site `SITE_NAME`. After the above command runs, this will be in the
    applicationHost.config:

        <location path="SITE_NAME">
            <system.webServer>
                <httpProtocol>
                    <customHeaders>
                        <add name="X-AddHeader" value="usingCarbon" />
                    </customHeaders>
                </httpProtocol>
            </system.webServer>
        <location path="SITE_NAME" />
    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    param(
        # The HTTP header name to add.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Name,

        # The HTTP header value to add.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $Value,

        # The location path to the site, directory, appliction, or virtual directory to configure. By default, headers
        # are added to global configuration.
        [Parameter(ParameterSetName='Local')]
        [String] $LocationPath
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $setArgs = @{}

        if ($LocationPath)
        {
            $setArgs['LocationPath'] = $LocationPath
        }

        $headers = [List[hashtable]]::New()
    }

    process
    {
        $headers.Add(@{ 'name' = $Name ; 'value' = $Value })
    }

    end
    {
        $headers | Set-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' `
                                          -CollectionName 'customHeaders' `
                                          @setArgs
    }
}
