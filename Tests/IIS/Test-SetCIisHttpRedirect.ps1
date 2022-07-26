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

$Port = 9877
$WebConfig = Join-Path $TestDir web.config
$SiteName = 'CarbonSetIisHttpRedirect'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-CIisWebsite -Name $SiteName -Path $TestDir -Bindings "http://*:$Port"
    if( Test-Path $WebConfig )
    {
        Remove-Item $WebConfig
    }
}

function Stop-Test
{
    Uninstall-CIisWebsite -Name $SiteName
}

function Test-ShouldRedirectSite
{
    Set-CIisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com' 
    Assert-Redirects
    Assert-FileDoesNotExist $webConfig # make sure committed to applicationHost.config
    $settings = Get-CIisHttpRedirect -SiteName $SiteName
    Assert-True $settings.GetAttributeValue('Enabled')
    Assert-Equal 'http://www.example.com' $settings.GetAttributeValue('destination')
    Assert-False $settings.GetAttributeValue('exactDestination')
    Assert-False $settings.GetAttributeValue('childOnly')
    Assert-Equal 302 $settings.GetAttributeValue('httpResponseStatus')
}

function Test-ShouldSetREdirectCustomizations
{
    Set-CIisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com' -HttpResponseStatus 301 -ExactDestination -ChildOnly
    Assert-Redirects
    $settings = Get-CIisHttpRedirect -SiteName $SiteName
    Assert-Equal 'http://www.example.com' $settings.GetAttributeValue('destination')
    Assert-Equal 301 $settings.GetAttributeValue('httpResponseStatus')
    Assert-True $settings.GetAttributeValue('exactDestination')
    Assert-True $settings.GetAttributeValue('childOnly')
}

function Test-ShouldSetToDefaultValues
{
    Set-CIisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com' -HttpResponseStatus 302 -ExactDestination -ChildOnly
    Assert-Redirects
    Set-CIisHttpRedirect -SiteName $SiteName -Destination 'http://www.example.com'
    Assert-Redirects

    $settings = Get-CIisHttpRedirect -SiteName $SiteName
    Assert-Equal 'http://www.example.com' $settings.GetAttributeValue('destination')
    Assert-Equal 302 $settings.GetAttributeValue('httpResponseStatus')
    Assert-False $settings.GetAttributeValue('exactDestination') 'exact destination not reverted'
    Assert-False $settings.GetAttributeValue('childOnly') 'child only not reverted'
}

function Test-ShouldSetRedirectOnPath
{
    Set-CIisHttpRedirect -SiteName $SiteName -Path SubFolder -Destination 'http://www.example.com'
    Assert-Redirects -Path Subfolder
    $content = Read-Url -Path 'NewWebsite.html'
    Assert-True ($content -match 'NewWebsite') 'Redirected root page'
    
    $settings = Get-CIisHttpREdirect -SiteName $SiteName -Path SubFolder
    Assert-True $settings.GetAttributeValue('enabled')
    Assert-Equal 'http://www.example.com' $settings.GetAttributeValue('destination')
}

function Read-Url($Path = '')
{
    $browser = New-Object Net.WebClient
    return $browser.downloadString( "http://localhost:$Port/$Path" )
}

function Assert-Redirects($Path = '')
{
    $numTries = 0
    $maxTries = 5
    $content = ''
    do
    {
        try
        {
            $content = Read-Url $Path
            if( $content -match 'Example Domain' )
            {
                break
            }
        }
        catch
        {
            Write-Verbose "Error downloading '$Path': $_"
        }
        $numTries++
        Start-Sleep -Milliseconds 100
    }
    while( $numTries -lt $maxTries )
}

