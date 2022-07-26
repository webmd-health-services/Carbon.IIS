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

$appPoolName = 'CarbonGetIisAppPool'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-CIisAppPool -Name $appPoolName
}

function Stop-Test
{
    if( (Test-CIisAppPool -Name $appPoolName) )
    {
        Uninstall-CIisAppPool -Name $appPoolName
    }
}

function Test-ShouldGetAllApplicationPools
{
    Install-CIisAppPool -Name 'ShouldGetAllApplicationPools'
    Install-CIisAppPool -Name 'ShouldGetAllApplicationPools2'
    try
    {
        $appPools = Get-CIisAppPool
        Assert-NotNull $appPools
        Assert-Is $appPools ([object[]])
        Assert-NotNull ($appPools | Where-Object { $_.Name -eq 'ShouldGetAllApplicationPools' })
        Assert-NotNull ($appPools | Where-Object { $_.Name -eq 'ShouldGetAllApplicationPools2' })
    }
    finally
    {
        Uninstall-CIisAppPool -Name 'ShouldGetAllApplicationPools'
        Uninstall-CIisAppPool -Name 'ShouldGetAllApplicationPools2'
    }
}

function Test-ShouldAddServerManagerMembers
{
    $appPool = Get-CIisAppPool -Name $appPoolName
    Assert-NotNull $appPool 
    Assert-NotNull $appPool.ServerManager
    $newAppPoolName = 'New{0}' -f $appPoolName
    Uninstall-CIisAppPool -Name $newAppPoolName
    $appPool.name = $newAppPoolName
    $appPool.CommitChanges()
    
    try
    {
        $appPool = Get-CIisAppPool -Name $newAppPoolName
        Assert-NotNull $appPool
        Assert-Equal $newAppPoolName $appPool.name
    }
    finally
    {
        Uninstall-CIisAppPool -Name $newAppPoolName
    }
        
}

