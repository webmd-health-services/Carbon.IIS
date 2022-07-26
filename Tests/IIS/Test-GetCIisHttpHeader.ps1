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

$siteName = 'CarbonGetIisHttpHeader'
$sitePort = 47939

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-CIisWebsite -Name $siteName -Path $TestDir -Binding ('http/*:{0}:*' -f $sitePort)
}

function Stop-Test
{
    Uninstall-CIisWebsite -Name $siteName
}

function Test-ShouldReturnAllHeaders
{
    $currentHeaders = @( Get-CIisHttpHeader -SiteName $siteName )
    
    Set-CIisHttpHeader -SiteName $siteName -Name 'X-Carbon-Header1' -Value 'Value1'
    Set-CIisHttpHeader -SiteName $siteName -Name 'X-Carbon-Header2' -Value 'Value2'
    
    $newHeaders = Get-CIisHttpHeader -SiteName $siteName
    Assert-NotNull $newHeaders
    Assert-True ($newHeaders.Length -ge 2)
}

function Test-ShouldAllowSearchingByWildcard
{
    $name = 'X-Carbon-GetIisHttpRedirect'
    $value = [Guid]::NewGuid()
    Set-CIisHttpHeader -SiteName $siteName -Name $name -Value $value
    
    ($name, 'X-Carbon*' ) | ForEach-Object {
        $header = Get-CIisHttpHeader -SiteName $siteName -Name $_
        Assert-NotNull $header
        Assert-Equal $name $header.Name
        Assert-Equal $value $header.Value
    }
    
    $header = Get-CIisHttpHeader -SiteName $siteName -Name 'blah*'
    Assert-Null $header
}

