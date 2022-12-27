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

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:siteName = 'Carbon-Set-CIisWebsiteSslCertificate'
    $script:cert = $null
    $script:appID = '990ae75d-b1c3-4c4e-93f2-9b22dfbfe0ca'
    $script:ipAddress = '43.27.98.0'
    $script:port = -1
    $script:allPort = -1
    Start-W3ServiceTestFixture
}

AfterAll {
    Complete-W3ServiceTestFixture
}


Describe 'Set-CIisWebsiteSslCertificate' {
    BeforeEach {
        $script:testDir = New-TestDirectory
        $script:port = New-Port
        $script:allPort = New-Port
        $bindings = @(
            (New-Binding -Protocol 'https' -IPAddress $script:ipAddress -Port $script:port),
            (New-Binding -Protocol 'https' -Port $script:allPort)
        )
        Install-CIisTestWebsite -Name $script:siteName -PhysicalPath $script:testDir -Binding $bindings
        $script:certPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonIisTestCertificate.cer' -Resolve
        $script:cert = Install-CCertificate -Path $script:certPath -StoreLocation LocalMachine -StoreName My -PassThru
    }

    AfterEach {
        Uninstall-CCertificate -Certificate $script:cert -StoreLocation LocalMachine -StoreName My
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should set website ssl certificate' {
        Set-CIisWebsiteSslCertificate -SiteName $script:siteName `
                                      -Thumbprint $script:cert.Thumbprint `
                                      -ApplicationID $script:appID
        try
        {
            $binding = Get-CSslCertificateBinding -IPAddress $script:ipAddress -Port $script:port
            $binding | Should -Not -BeNullOrEmpty
            $binding.CertificateHash | Should -Be $script:cert.Thumbprint
            $binding.ApplicationID | Should -Be $script:appID

            $binding = Get-CSslCertificateBinding -Port $script:allPort
            $binding | Should -Not -BeNullOrEmpty
            $binding.CertificateHash | Should -Be $script:cert.Thumbprint
            $binding.ApplicationID | Should -Be $script:appID

        }
        finally
        {
            Remove-CSslCertificateBinding -IPAddress $script:ipAddress -Port $script:port
            Remove-CSslCertificateBinding -Port $script:allPort
        }
    }

    It 'should support what if' {
        $bindings = @( Get-CSslCertificateBinding )
        Set-CIisWebsiteSslCertificate -SiteName $script:siteName `
                                      -Thumbprint $script:cert.Thumbprint `
                                      -ApplicationID $script:appID `
                                      -WhatIf
        $newBindings = @( Get-CSslCertificateBinding )
        $newBindings | Should -HaveCount $bindings.Length
    }

    It 'should support website without ssl bindings' {
        Install-CIisTestWebsite -Name $script:siteName -PhysicalPath $script:testDir
        $bindings = @( Get-CSslCertificateBinding )
        Set-CIisWebsiteSslCertificate -SiteName $script:siteName `
                                      -Thumbprint $script:cert.Thumbprint `
                                      -ApplicationID $script:appID
        $newBindings = @( Get-CSslCertificateBinding )
        $newBindings | Should -HaveCount $bindings.Length
    }

}
