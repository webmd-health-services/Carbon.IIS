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

$appPoolName = 'CarbonTestUninstallAppPool'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Uninstall-CIisAppPool -Name $appPoolName
    Assert-False (Test-CIisAppPool -Name $appPoolName)
}

function Stop-Test
{
    Uninstall-CIisAppPool -Name $appPoolName
}

function Test-ShouldRemoveAppPool
{
    Install-CIisAppPool -Name $appPoolName
    Assert-True (Test-CIisAppPool -Name $appPoolName)
    Uninstall-CIisAppPool -Name $appPoolName 
    Assert-False (Test-CIisAppPool -Name $appPoolName)    
}

function Test-ShouldRemvoeMissingAppPool
{
    $missingAppPool = 'IDoNotExist'
    Assert-False (Test-CIisAppPool -Name $missingAppPool)
    Uninstall-CIisAppPool -Name $missingAppPool 
    Assert-False (Test-CIisAppPool -Name $missingAppPool)    
}

function Test-ShouldSupportWhatIf
{
    Install-CIisAppPool -Name $appPoolName
    Assert-True (Test-CIisAppPool -Name $appPoolName)
    
    Uninstall-CIisAppPool -Name $appPoolName -WhatIf
    Assert-True (Test-CIisAppPool -Name $appPoolName)
}

