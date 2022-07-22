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

$siteName = 'Carbon-Set-CIisWebsiteSslCertificate'
$cert = $null
$appID = '990ae75d-b1c3-4c4e-93f2-9b22dfbfe0ca'
$ipAddress = '43.27.98.0'
$port = '443'
$allPort = '8013'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-CIisWebsite -Name $siteName -Path $TestDir -Bindings @( "https/$ipAddress`:$port`:", "https/*:$allPort`:" )
    $certPath = Join-Path -Path $TestDir -ChildPath 'CarbonTestCertificate.cer' -Resolve
    $cert = Install-CCertificate -Path $certPath -StoreLocation LocalMachine -StoreName My -PassThru
}

function Stop-Test
{
    Uninstall-CCertificate -Certificate $cert -StoreLocation LocalMachine -StoreName My
    Uninstall-CIisWebsite -Name $siteName
}

function Test-ShouldSetWebsiteSslCertificate
{
    Set-CIisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID
    try
    {
        $binding = Get-CSslCertificateBinding -IPAddress $ipAddress -Port $port
        Assert-NotNull $binding
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
        Assert-Equal $appID $binding.ApplicationID
        
        $binding = Get-CSslCertificateBinding -Port $allPort
        Assert-NotNull $binding
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
        Assert-Equal $appID $binding.ApplicationID
        
    }
    finally
    {
        Remove-CSslCertificateBinding -IPAddress $ipAddress -Port $port 
        Remove-CSslCertificateBinding -Port $allPort
    } 
}

function Test-ShouldSupportWhatIf
{
    $bindings = @( Get-CSslCertificateBinding )
    Set-CIisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID -WhatIf
    $newBindings = @( Get-CSslCertificateBinding )
    Assert-Equal $bindings.Length $newBindings.Length
}

function Test-ShouldSupportWebsiteWithoutSslBindings
{
    Install-CIisWebsite -Name $siteName -Path $TestDir -Bindings @( 'http/*:80:' )
    $bindings = @( Get-CSslCertificateBinding )
    Set-CIisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID
    $newBindings = @( Get-CSslCertificateBinding )
    Assert-Equal $bindings.Length $newBindings.Length
}

