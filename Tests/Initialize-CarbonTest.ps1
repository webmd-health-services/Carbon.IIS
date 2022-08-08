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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
