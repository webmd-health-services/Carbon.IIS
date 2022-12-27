
using module '..\..\Carbon.IIS'

using namespace Microsoft.Web.Administration
using namespace System.Text

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String] $Name,

    [Parameter(Mandatory)]
    [ValidateSet('website', 'application pool')]
    [String] $TargetObjectType,

    [Parameter(Mandatory)]
    [String] $TargetPropertyDescription,

    [Parameter(Mandatory)]
    [Uri] $DocumentationUrl,

    [String] $PropertyName
)

#Requires -Version 7.1
Set-StrictMode -Version 'Latest'

$tokens = @{
    AFTER_ALL = ''; # ✔
    AFTER_EACH = ''; # ✔
    BEFORE_ALL = ''; # ✔
    BEFORE_EACH = ''; # ✔
    CMD_NAME = $Name; # ✔
    CMD_NAME_PARAMETER_NAME = ''; # ✔
    CMD_PARAMETERS = '';
    DOCUMENTATION_TITLE = ''; # ✔
    DOCUMENTATION_URL = $DocumentationUrl; # ✔
    GET_CMD_NAME = ''; # ✔
    NON_DEFAULT_ARGS = ''; # ✔
    PARAMETER_LIST = '';
    PROPERTY_NAME = $PropertyName -join '.'; # ✔
    TARGET_OBJECT_TYPE = $TargetObjectType; # ✔
    TARGET_PROPERTY_DESCRIPTION = $TargetPropertyDescription; # ✔
    TARGET_VAR_NAME = ''; # ✔
}

if( $TargetObjectType -eq 'website' )
{
    $tokens['CMD_NAME_PARAMETER_NAME'] = 'SiteName'
    $tokens['GET_CMD_NAME'] = 'Get-CIisWebsite'
    $tokens['TARGET_VAR_NAME'] = 'siteName'
    $tokens['BEFORE_EACH'] =
        "Install-CIisTestWebsite -Name `$script:siteName -PhysicalPath (New-TestDirectory)"
    $tokens['AFTER_EACH'] = 'Uninstall-CIisWebsite -Name $script:siteName'
}
elseif( $TargetObjectType -eq 'application pool' )
{
    $tokens['CMD_NAME_PARAMETER_NAME'] = 'AppPoolName'
    $tokens['GET_CMD_NAME'] = 'Get-CIisAppPool'
    $tokens['TARGET_VAR_NAME'] = 'appPoolName'
    $tokens['BEFORE_EACH'] = 'Install-CIisAppPool -Name $script:appPoolName'
    $tokens['AFTER_EACH'] = 'Uninstall-CIisAppPool -Name $script:appPoolName'
}
else
{
    $msg = "Unsupported target object type ""$($TargetObjectType)"". This script needs to be updated to support it."
    Write-Error -Message $msg -ErrorAction Stop
    exit 1
}

$ProgressPreference = 'SilentlyContinue'
$docPage = Invoke-WebRequest -Uri $DocumentationUrl -TimeoutSec 5
if( -not $docPage -or $docPage.Content -notmatch '<title>([^<]*)</title>' )
{
    $msg = "Failed to extract title from HTML at $($DocumentationUrl)."
    Write-Error $msg -ErrorAction Stop
}

$tokens['DOCUMENTATION_TITLE'] = [Web.HttpUtility]::HtmlDecode(($Matches[1] -replace ' \|.*$', ''))


$target = & $tokens['GET_CMD_NAME'] -Defaults
foreach( $propertyNameItem in $PropertyName )
{
    $target = $target.$propertyNameItem
}

$nonDefaultArgs = [StringBuilder]::New()
$cmdParameters = [StringBuilder]::New()
$paramList = [StringBuilder]::New()
$typeMap = @{
    'string' = 'String';
    'uint' = 'UInt32';
    'enum' = 'Enum';
    'timeSpan' = 'TimeSpan';
}
$indent = '        '
$target.Attributes |
    Sort-Object -Property 'Name' |
    ForEach-Object {
        $attr = $_
        $paramName = $attr.Name.Substring(0,1).ToUpperInvariant() + $attr.Name.Substring(1)

        [void]$paramList.Append($paramName).Append(', ')

        [void]$nonDefaultArgs.AppendLine("$($indent)'$($attr.Name)' = VALUE;")

        $typeName = $attr.Schema.Type
        if( $typeMap.ContainsKey($typeName) )
        {
            $typeName = $typeMap[$typeName]
        }
        if( $paramName -eq 'Password' )
        {
            $typeName = 'securestring'
        }
        [void]$cmdParameters.AppendLine(@"

$($indent)# Sets the IIS $($TargetObjectType)'s $($TargetPropertyDescription) ``$($attr.Name)`` setting.
$($indent)[$($typeName)] `$$($paramName),
"@)
    }

$tokens['NON_DEFAULT_ARGS'] = $nonDefaultArgs.ToString().Trim()
$tokens['CMD_PARAMETERS'] = $cmdParameters.ToString().Trim().TrimEnd(',')
$tokens['PARAMETER_LIST'] = $paramList.ToString().Trim().TrimEnd(', ') -replace '([^ ]+)$', 'and/or $1'

$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Carbon.IIS\Functions\$($Name).ps1"
$testPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Tests\$($Name).Tests.ps1"
Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '%CMD_NAME%.ps1') `
          -Destination $functionpath
Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '%CMD_NAME%.Tests.ps1') `
          -Destination $testPath

foreach( $path in @($functionPath, $testPath) )
{
    $content = Get-Content -Path $path -Raw
    foreach( $token in $tokens.Keys )
    {
        $content = $content -replace "%$($token)%", $tokens[$token]
    }
    $content | Set-Content -Path $path -NoNewline
}

