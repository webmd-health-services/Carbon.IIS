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
[CmdletBinding()]
param(
    # The name of the function to create. "Carbon.IIS\Functions\$($Name).ps1" and "Tests\$($Name).Tests.ps1" files will
    # be created.
    [Parameter(Mandatory)]
    [String] $Name,

    # The configuration section path the function will be used to configure. The script will inspect the schema for that
    # configuration section to determine what parameters the function should have.
    [Parameter(Mandatory)]
    [String] $SectionPath,

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

$section = Get-CIisConfigurationSection -SectionPath $SectionPath
if( -not $section )
{
    return
}

$section

$paramNames = @{}

$content = [Text.StringBuilder]::New()
[void]$content.Append(@"
function $($Name)
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [String] `$SiteName,

        [String] `$VirtualPath = ''
"@)
    foreach( $attr in $section.Schema.AttributeSchemas )
    {
        $paramName = [char]::ToUpperInvariant($attr.Name[0]) + $attr.Name.Substring(1, $attr.Name.Length - 1)
        $paramNames[$attr.Name] = $paramName

        $type = $attr.Type
        $typeName = 'String'
        if( $type -eq [bool] )
        {
            $typeName = 'switch'
        }
        elseif( $type -eq [int] )
        {
            $typeName = 'int'
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

        [$($typeName)] `$$($paramName)
"@)
    }

    [void]$Content.Append(@"

    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet `$PSCmdlet -Session `$ExecutionContext.SessionState

    `$paramNames = @('$(($paramNames.Keys | Sort-Object) -join "', '")')

    `$sectionPath = '$($SectionPath)'

    `$PSBoundParameters.GetEnumerator() |
        Where-Object 'Key' -In `$paramNames |
        Set-CIisConfigurationAttribute -SiteName `$SiteName -VirtualPath `$VirtualPath -SectionPath `$sectionPath
}
"@)

$content.ToString() | Set-Content -Path $destinationPath

[void]$content.Clear()

$intTestValue = 1
$enumTestValue = 0
$boolTestValue = $false

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

    if( $type -eq [String] )
    {
        return "'$(([IO.Path]::GetRandomFileName() -replace '\.', ''))'"
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

    $msg = "Don't know how to generate test data for attribute ""$($ParameterName)"" of type ""$($Type)""."
    Write-Error -Message $msg
}

function Get-TestArgumentContent
{
    [CmdletBinding()]
    param(
    )

    $argContent = [Text.StringBuilder]::New()

    foreach( $attrSchema in ($section.Schema.AttributeSchemas | Sort-Object -Property 'Name') )
    {
        $paramName = $attrSchema.Name
        $value = Get-TestValue -Type $attrSchema.Type -ParameterName $paramName
        if( $paramName -eq 'Password' )
        {
            $value = "(ConvertTo-SecureString -String $($value) -AsPlainText -Force)"
        }
        $line = "            $($paramNames[$attrSchema.Name]) = $($value);"
        [void]$argContent.AppendLine($line)
    }
    return $argContent.ToString().Trim()
}

[void]$content.Append(@"

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    `$script:port = 9877
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

        `$section = Get-CIisConfigurationSection -SiteName `$script:siteName ``
                                                -VirtualPath `$ForVirtualPath ``
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

Describe 'Set-CIisAnonymousAuthentication' {
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
$content.ToString() | Set-Content -Path $testDestinationPath
