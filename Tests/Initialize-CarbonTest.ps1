# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding()]
param(
    [Switch]
    $ForDsc
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

if( $env:COMPUTERNAME -eq $env:USERNAME )
{
    throw ('Can''t run Carbon tests. The current user''s username ({0}) is the same as the computer name ({1}). This causes problems with resolving identities, getting items from the registry, etc. Please re-run these tests using a different account.')
}

$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.IIS\Import-Carbon.IIS.ps1' -Resolve

if( (Test-Path -Path 'env:APPVEYOR') )
{
    # On the build server, files never change, so we only ever need to import Carbon once.
    if( -not (Get-Module -Name 'Carbon.IIS') )
    {
        & $importCarbonPath
    }
}
else 
{
    # On developer computers, only import Carbon if it has changed since the last import.
    if( -not (Test-Path -Path 'variable:CarbonIisLastImportedAt') )
    {
        $Global:CarbonIisLastImportedAt = [DateTime]::MinValue
    }

    $startedAt = Get-Date
    $mostRecentModificationAt = 
        Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.IIS') -File -Recurse |
        Sort-Object -Property 'LastWriteTime' -Descending |
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'LastWriteTime'
    $checkDuration = (Get-Date) - $startedAt
    $msg = "It took ""$($checkDuration.TotalSeconds)"" seconds to check if any of the Carbon.IIS module's files " +
           'changed.'
    Write-Debug -Message $msg

    $moduleImported = $null -ne (Get-Module -Name 'Carbon.IIS')
    $moduleUpdated = $mostRecentModificationAt -gt $CarbonIisLastImportedAt
    if( -not $moduleImported -or $moduleUpdated )
    {
        Write-Verbose -Message ('Importing Carbon.') -Verbose
        Write-Verbose -Message ('Module Already Imported?            {0}' -f $moduleImported) -Verbose
        Write-Verbose -Message ('Module Modified Since Last Import?  {0}' -f $moduleUpdated) -Verbose
        Write-Verbose -Message ('              CarbonIisLastImportedAt  {0}' -f $CarbonIisLastImportedAt) -Verbose
        Write-Verbose -Message ('                LastModificationAt  {0}' -f $mostRecentModificationAt) -Verbose
        if( (Get-Module -Name 'Carbon.IIS') )
        {
            Remove-Module -Name 'Carbon.IIS' -Force
        }
        & $importCarbonPath 
        $Global:CarbonIisLastImportedAt = Get-Date
    }
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Carbon.Cryptography' -Resolve) `
              -Function @('Install-CCertificate', 'Uninstall-CCertificate')

# We have to *only* import the Carbon functions we need so we don't end up using and testing the original Carbon's IIS
# functions.
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Carbon' -Resolve) `
              -Function @(
                    'Get-CPrivilege',
                    'Grant-CPermission',
                    'Grant-CPrivilege',
                    'Get-CSslCertificateBinding',
                    'Install-CUser',
                    'New-CCredential',
                    'New-CTempDirectory',
                    'Remove-CSslCertificateBinding',
                    'Resolve-CFullPath',
                    'Revoke-CPrivilege',
                    'Set-CSslCertificateBinding',
                    'Test-CIdentity',
                    'Test-CUser'
                )

Grant-CPermission -Path $PSScriptRoot -Identity 'IIS_IUSRS' -Permission ReadAndExecute

$password = 'Tt6QML1lmDrFSf'
[pscredential]$global:CarbonTestUser = New-CCredential -UserName 'CarbonTestUser' -Password $password

if( -not (Test-CUser -Username $CarbonTestUser.UserName) )
{
    Install-CUser -Credential $CarbonTestUser -Description 'User used during Carbon tests.'

    $usedCredential = $false
    while( $usedCredential -ne $CarbonTestUser.UserName )
    {
        try
        {
            Write-Verbose -Message ('Attempting to launch process as "CarbonTestUser".') -Verbose
            $usedCredential = 
                Start-Job -ScriptBlock { [Environment]::UserName } -Credential $CarbonTestUser  | 
                Wait-Job |
                Receive-Job
        }
        catch 
        {
            Start-Sleep -Milliseconds 100
        }
    }
}