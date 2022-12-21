<#
.SYNOPSIS
Auto-generates the content for a function that sets the attributes on a specific configuration section.

.DESCRIPTION
The `New-SetAttributeFunction.ps1` scripts generates a function (and tests) for a function that sets the attributes on
a specific configuration section. Pass the name of the new function to the `Name` parameter. Pass the configuration
section path to the `SectionPath` parameter. The script will create "Carbon.IIS\Function\$($Name).ps1" with parameters
for each attribute that can be set on the configuration section given the `SectionPath` parameter.

If any of the attributes in the configuration section are enumeration values, you must pass the type name of the
equivalent enum in the Microsoft.Web.Administration assembly as a key/value pair to the `AttributeEnumMap` parameter.
For example, the logonMethod attribute in the system.webServer/security/authentication/anonymousAuthentiction
configuration section maps to the `[Microsoft.Web.Administration.AuthenticationLogonMethod]` type, so you would pass
`@{ 'logonMethod' = 'Microsoft.Web.Administration.AuthenticationLogonMethod' }` to the `AttributeEnumMap` parameter.

A Pester test file will also be saved to "Tests\$($Name).Tests.ps1".

If either the function file or test file already exist, you'll get an error and nothing will be written. To overwrite
the existing files, use the `Force` (switch).

.EXAMPLE
.\New-SetAttributeFunction.ps1 -Name 'Set-CIisAnonymousAuthentication' -SectionPath 'system.webServer/security/authentication/anonymousAuthentication' -force -AttributeEnumMap @{ 'logonMethod' = 'Microsoft.Web.Administration.AuthenticationLogonMethod' }

Demonstrates how `New-SetAttributeFunction.ps1` was called to create a `Set-CIisAnonymousAuthentication` function for
configuring anonymous authentication.
#>

using namespace Microsoft.Web.Administration

[CmdletBinding()]
param(
    # The name of the function to create. "Carbon.IIS\Functions\$($Name).ps1" and "Tests\$($Name).Tests.ps1" files will
    # be created.
    [Parameter(Mandatory)]
    [String] $Name,

    # The configuration section path the function will be used to configure. The script will inspect the schema for that
    # configuration section to determine what parameters the function should have.
    [Parameter(Mandatory, ParameterSetName='BySectionPath')]
    [String] $SectionPath,

    [Parameter(Mandatory, ParameterSetName='ByConfiguraionElement', ValueFromPipeline)]
    [ConfigurationElement] $ConfigurationElement,

    [Parameter(Mandatory)]
    [ValidateSet('Site', 'ApplicationPool')]
    [String] $ConfigurationElementType,

    [String] $ConfigurationElementPropertyName,

    # If any of the configuration section's attributes map to enum values, this hashtable should be a key/value map of
    # the attribute name with the enumeration type name, e.g.
    # `@{ 'logonMethod' = 'Microsoft.Web.Administration.AuthenticationLogonMethod' }`
    [hashtable] $AttributeEnumMap = @{},

    # If set, any existing function or test file will be overwritten by the script.
    [switch] $Force
)

Set-StrictMode -Version 'Latest'

$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath "Carbon.IIS\Functions\$($Name).ps1"

if( -not $Force -and (Test-Path -Path $destinationPath) )
{
    Write-Error -Message "Destination file ""$($destinationPath)"" exists. Use the -Force (switch) to overwrite."
    exit 1
}

$testDestinationPath = Join-Path -Path $PSScriptRoot -ChildPath "Tests\$($Name).Tests.ps1"
if( -not $Force -and (Test-Path -Path $testDestinationPath) )
{
    $msg = "Destination test file ""$($testDestinationPath)"" exists. Use the -Force (switch) to overwrite."
    Write-Error -Message $msg
    exit 1
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.IIS' -Resolve) -Force

if( -not $ConfigurationElement )
{
    $ConfigurationElement = Get-CIisConfigurationSection -SectionPath $SectionPath
    if( -not $ConfigurationElement )
    {
        return
    }
}

$paramNames = @{}
$typeShortNamesMap = @{
    'uint' = 'UInt32';
    'timeSpan' = 'TimeSpan';
}

$content = [Text.StringBuilder]::New()
[void]$content.Append(@"

function $($Name)
{
    <#
    .DESCRIPTION
    The `$($Name)` function

    .LINK

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(

"@)

if( $SectionPath )
{
    [void]$content.Append(@"
        # The IIS website whose settings to configure.
        [Parameter(Mandatory)]
        [String] `$SiteName,

        # The virtual path under the website whose settings to configure.
        [String] `$VirtualPath = ''
"@)
}
else
{
    $targetParamName = 'SiteName'
    $getCmdName = 'Get-CIisWebsite'
    $targetVarName = 'site'
    $targetDesc = 'website'
    if( $ConfigurationElementType -eq 'ApplicationPool' )
    {
        $targetParamName = 'AppPoolName'
        $getCmdName = 'Get-CIisAppPool'
        $targetVarName = 'appPool'
        $targetDesc = 'application pool'
    }
    [void]$content.Append(@"
        # The IIS $($targetDesc) whose configuration to set.
        [Parameter(Mandatory)]
        [String] `$$($targetParamName)
"@)
}
    foreach( $attr in $ConfigurationElement.Schema.AttributeSchemas )
    {
        $paramName = [char]::ToUpperInvariant($attr.Name[0]) + $attr.Name.Substring(1, $attr.Name.Length - 1)
        $paramNames[$attr.Name] = $paramName

        $type = $attr.Type
        $typeName = "$($type)"
        if( $typeShortNamesMap.ContainsKey($type) )
        {
            $typeName = $typeShortNamesMap[$type]
        }
        elseif( $type -eq 'enum' )
        {
            if( -not $AttributeEnumMap.ContainsKey($paramName) )
            {
                $msg = "Unable to generate code for attribute ""$($attr.Name)"": it's an enum, but the enum type " +
                       'name is missing from the "AttributeEnumMap" parameter.'
                Write-Error -Message $msg -ErrorAction Stop
            }
            $typeName = $AttributeEnumMap[$paramName]
        }
        elseif( $paramName -eq 'Password' )
        {
            $typeName = 'SecureString'
        }
        [void]$content.Append(@"
,

        # Sets the IIS $($targetDesc)'s ``$($paramName.Substring(0,10).ToLowerInvariant())$($paramName.Substring(1))`` setting.
        [$($typeName)] `$$($paramName)
"@)
    }

    [void]$Content.Append(@"

    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet `$PSCmdlet -Session `$ExecutionContext.SessionState

"@)

    if( $SectionPath )
    {
        [void]$Content.Append(@"

    `$paramNames = @('$(($paramNames.Keys | Sort-Object) -join "', '")')

    `$sectionPath = '$($SectionPath)'

    `$PSBoundParameters.GetEnumerator() |
        Where-Object 'Key' -In `$paramNames |
        Set-CIisConfigurationAttribute -LocationPath (Join-CIisVirtualPath -Path `$SiteName, `$VirtualPath) -SectionPath `$sectionPath
"@)
    }
    else
    {
        $targetPropertyDescription = ($ConfigurationElementPropertyName -creplace '([A-Z])', '.$1').ToLowerInvariant()  `
                                                                        -replace '\.+', ' '
        [void]$Content.Append(@"

    `$$($targetVarName) = $($getCmdName) -Name `$$($targetParamName)
    if( -not `$$($targetVarName) )
    {
        return
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement `$$($targetVarName).$($ConfigurationElementPropertyName) ``
                                     -PSCmdlet `$PSCmdlet ``
                                     -Target """`$(`$$($targetParamName))"" IIS $($targetDesc)'s$($targetPropertyDescription)"
"@)
    }
[void]$content.Append(@"

}
"@)

$content.ToString() | Set-Content -Path $destinationPath

[void]$content.Clear()

$intTestValue = 1
$enumTestValue = 0
$boolTestValue = $false
[UInt32] $uintTestValue = 1
[TimeSpan] $timeSpanTestValue = [TimeSpan]'00:00:01'

function Get-TestValue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Type] $Type,

        [Parameter(Mandatory)]
        [String] $ParameterName
    )

    if( $type -eq [bool] )
    {
        $script:boolTestValue = -not $script:boolTestValue
        return "`$$($script:boolTestValue.ToString().ToLowerInvariant())"
    }

    if( $type -eq [int] )
    {
        return ($script:intTestValue++)
    }

    if( $type -eq [Enum] )
    {
        if( $AttributeEnumMap.ContainsKey($ParameterName) )
        {
            $enumTypeName = $AttributeEnumMap[$ParameterName]
            return "[$($enumTypeName)]::$([enum]::Parse($enumTypeName, ($script:enumTestValue++)))"
        }

        return ($script:enumTestValue++)
    }

    if( $type -eq [UInt32] )
    {
        return ($script:uintTestValue++)
    }

    if( $type -eq [TimeSpan] )
    {
        $script:timeSpanTestValue = $script:timeSpanTestValue.Add($script:timeSpanTestValue)
        return $script:timeSpanTestValue
    }

    if( $type -eq [String] )
    {
        return "'$(([IO.Path]::GetRandomFileName() -replace '\.', ''))'"
    }

    $msg = "Don't know how to generate test data for attribute ""$($ParameterName)"" of type ""$($Type)""."
    Write-Error -Message $msg
}

function Get-TestArgumentContent
{
    [CmdletBinding()]
    param(
    )

    $argContent = [Text.StringBuilder]::New()

    foreach( $attrSchema in ($ConfigurationElement.Schema.AttributeSchemas | Sort-Object -Property 'Name') )
    {
        $paramName = $attrSchema.Name
        $typeName = $attrSchema.Type
        if( $typeShortNamesMap.ContainsKey($typeName) )
        {
            $typeName = $typeShortNamesMap[$typeName]
        }
        $value = Get-TestValue -Type $typeName -ParameterName $paramName
        if( $paramName -eq 'Password' )
        {
            $value = "(ConvertTo-SecureString -String $($value) -AsPlainText -Force)"
        }
        $line = "            $($paramNames[$attrSchema.Name]) = $($value);"
        [void]$argContent.AppendLine($line)
    }
    return $argContent.ToString().Trim()
}

if( $SectionPath )
{
    [void]$content.Append(@"

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    `$script:webConfigPath = ''
    `$script:siteName = `$PSCommandPath | Split-Path -Leaf
    `$script:testWebRoot = ''

    & (Join-Path -Path `$PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    function GivenVirtualPath
    {
        param(
            [Parameter(Mandatory)]
            [String] `$Path
        )

        New-Item -Path (Join-Path -Path `$script:testWebRoot -ChildPath `$Path) -ItemType 'Directory'
    }

    function ThenAttributesSetTo
    {
        param(
            [String] `$ForVirtualPath = '',

            [hashtable] `$ExpectedValues = @{},

            [switch] `$Defaults
        )

        `$sectionPath = '$($SectionPath)'

        if( `$Defaults )
        {
            `$section = Get-CIisConfigurationSection -SectionPath `$sectionPath
            foreach( `$attr in `$section.Attributes )
            {
                if( `$ExpectedValues.ContainsKey(`$attr.Name) )
                {
                    continue
                }

                `$ExpectedValues[`$attr.Name] = `$attr.Value
            }
        }

        `$locationPath = Join-CIisLocationPath -Path `$script:siteName -ChildPath `$ForVirtualPath
        `$section = Get-CIisConfigurationSection -LocationPath `$locationPath ``
                                                -SectionPath `$sectionPath
        foreach( `$attrName in `$ExpectedValues.Keys )
        {
            `$expectedValue = `$ExpectedValues[`$attrName]
            if( `$expectedValue -is [SecureString] )
            {
                `$expectedValue = [pscredential]::New('i', `$expectedValue).GetNetworkCredential().Password
            }
            `$section.GetAttributeValue(`$attrName) | Should -Be `$expectedValue
        }
    }

    function ThenCommittedToAppHost
    {
        `$script:webConfigPath | Should -Not -Exist # make sure committed to applicationHost.config
    }

    function WhenSetting
    {
        param(
            [hashtable] `$WithArgument = @{}
        )

        `$Global:Error.Clear()
        $($Name) -SiteName `$script:siteName @WithArgument
    }
}

Describe '$($Name)' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        `$script:testWebRoot = New-TestDirectory
        Install-CIisWebsite -Name `$script:siteName -Path `$script:testWebRoot -Bindings "http://*:`$(`$script:port)"
        `$script:webConfigPath = Join-Path -Path `$script:testWebRoot -ChildPath 'web.config'
        if( Test-Path `$script:webConfigPath )
        {
            Remove-Item `$script:webConfigPath
        }
    }

    AfterEach {
        Uninstall-CIisWebsite -Name `$script:siteName
    }

    It 'should set attributes' {
        `$setArgs = @{
            $(Get-TestArgumentContent)
        }
        WhenSetting -WithArgument `$setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo `$setArgs
    }

    It 'should set attributes on virtual path' {
        `$setArgs = @{
            $(Get-TestArgumentContent)
            VirtualPath = 'somepath';
        }
        GivenVirtualPath 'somepath'
        WhenSetting -WithArgument `$setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo -Defaults
        `$setArgs.Remove('VirtualPath')
        ThenAttributesSetTo -ForVirtualPath 'somepath' `$setArgs
    }

    It 'should support WhatIf' {
        `$setArgs = @{
            $(Get-TestArgumentContent)
            WhatIf = `$true;
        }
        WhenSetting -WithArgument `$setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo -Defaults
    }

    It 'should not update if values have not changed' {
        `$setArgs = @{
            $(Get-TestArgumentContent)
        }
        WhenSetting -WithArgument `$setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo `$setArgs
        `$appHostConfigPath =
            Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config' -Resolve
        `$appHostUpdatedAt = Get-Item -Path `$appHostConfigPath
        WhenSetting -WithArgument `$setArgs
        Get-Item -Path `$appHostConfigPath |
            Select-Object -ExpandProperty 'LastWriteTimeUtc' |
            Should -Be `$appHostUpdatedAt.LastWriteTimeUtc
    }
}
"@)
}
else
{
    [void]$content.Append(@"
using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path `$PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    `$script:testNum = 0

    # All non-default values.
    `$script:nonDefaultArgs = @{
        'FILL IN NON-DEFAULT VALUES' = 'THEN REMOVE THIS LINE';

"@)
    foreach( $attrSchema in ($ConfigurationElement.Schema.AttributeSchemas | Sort-Object -Property 'Name') )
    {
        [void]$content.AppendLine("        '$($attrSchema.Name)' = $($attrSchema.DefaultValue);")
    }

    [void]$content.Append(@"
    }

    # Sometimes the default values in the schema aren't quite the default values.
    `$script:notQuiteDefaultValues = @{
    }

    function ThenHasDefaultValues
    {
        ThenHasValues @{}
    }

    function ThenHasValues
    {
        param(
            [hashtable] `$Values = @{}
        )

        `$$($targetVarName) = $($getCmdName) -Name `$script:$($targetVarName)Name
        `$$($targetVarName)  | Should -Not -BeNullOrEmpty

        `$target = `$$($targetVarName).$($ConfigurationElementPropertyName)
        `$target | Should -Not -BeNullOrEmpty

        foreach( `$attr in `$target.Schema.AttributeSchemas )
        {
            `$currentValue = `$target.GetAttributeValue(`$attr.Name)
            `$expectedValue = `$attr.DefaultValue
            `$becauseMsg = 'default'
            if( `$script:notQuiteDefaultValues.ContainsKey(`$attr.Name))
            {
                `$expectedValue = `$script:notQuiteDefaultValues[`$attr.Name]
            }

            if( `$Values.ContainsKey(`$attr.Name) )
            {
                `$expectedValue = `$Values[`$attr.Name]
                `$becauseMsg = 'custom'
            }

            if( `$currentValue -is [TimeSpan] )
            {
                if( `$expectedValue -match '^\d+$' )
                {
                    `$expectedValue = [TimeSpan]::New([long]`$expectedValue)
                }
                else
                {
                    `$expectedValue = [TimeSpan]`$expectedValue
                }
            }

            `$currentValue | Should -Be `$expectedValue -Because "should set `$(`$attr.Name) to `$(`$becauseMsg) value"
        }
    }
}

Describe '$($Name)' {

"@)

    if( $ConfigurationElementType -eq 'Site')
    {
        [void]$content.Append(@"
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name '$($Name)'
    }

    AfterAll {
        Uninstall-CIisAppPool -Name '$($Name)'
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        `$script:$($targetVarName)Name = "$($Name)`$(`$script:testNum++)"
        `$webroot = New-TestDirectory
        Install-CIisWebsite -Name `$script:$($targetVarName)Name -PhysicalPath `$webroot -AppPoolName '$($Name)')
    }

    AfterEach {
        Uninstall-CIisWebsite -Name `$script:$($targetVarName)Name
    }
"@)
    }
    else
    {
        [void]$content.Append(@"
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        `$script:$($targetVarName)Name = "$($Name)`$(`$script:testNum++)"
        Install-CIisAppPool -Name `$script:$($targetVarName)Name
    }

    AfterEach {
        Install-CIisAppPool -Name `$script:$($targetVarName)Name
    }
"@)
    }

    [void]$content.Append(@"

    It 'should set and reset all log file values' {
        $($Name) -$($targetParamName) `$script:$($targetVarName)Name @nonDefaultArgs
        ThenHasValues `$nonDefaultArgs

        $($Name) -$($targetParamName) `$script:$($targetVarName)Name
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        $($Name) -$($targetParamName) `$script:$($targetVarName)Name @nonDefaultArgs -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        $($Name) -$($targetParamName) `$script:$($targetVarName)Name @nonDefaultArgs
        ThenHasValues `$nonDefaultArgs
        $($Name) -$($targetParamName) `$script:$($targetVarName)Name -WhatIf
        ThenHasValues `$nonDefaultArgs
    }

    It 'should change values and reset to defaults' {
        $($Name) -$($targetParamName) `$script:$($targetVarName)Name @nonDefaultArgs -ErrorAction Ignore
        ThenHasValues `$nonDefaultArgs

        `$someArgs = @{
            'FILL ME IN' = '';
        }
        $($Name) -$($targetParamName) `$script:$($targetVarName)Name @someArgs
        ThenHasValues `$someArgs
    }
}
"@)
}
$content.ToString() | Set-Content -Path $testDestinationPath
