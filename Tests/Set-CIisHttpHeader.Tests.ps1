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

    $script:siteName = $null
    $script:testNum = 0
    $script:testDir = $null

    Start-W3ServiceTestFixture
}

AfterAll {
    Complete-W3ServiceTestFixture
}

Describe 'Set-CIisHttpHeader' {

    BeforeEach {
        $script:testDir = New-TestDirectory
        $script:siteName = "Set-CIisHttpHeader$($script:testNum)"
        $script:testNum += 1
        Install-CIisTestWebsite -Name $script:siteName -PhysicalPath $script:testDir
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should create new header()' {
        $name = 'X-Carbon-SetIisHttpHeader'
        $value = 'Brownies'
        $header = Get-CIisHttpHeader -SiteName $script:siteName -Name $name
        $header | Should -BeNullOrEmpty
        $result = Set-CIisHttpHeader -SiteName $script:siteName -Name $name -Value $value
        $result | Should -BeNullOrEmpty
        $header = Get-CIisHttpHeader -SiteName $script:siteName -Name $name
        $header | Should -Not -BeNullOrEmpty
        $header.Name | Should -Be $name
        $header.Value | Should -Be $value
    }

    It 'should set existing header()' {
        $name = 'X-Carbon-SetIisHttpHeader'
        $value = 'Brownies'
        Set-CIisHttpHeader -SiteName $script:siteName -Name $name -Value $value

        $newValue = 'Blondies'
        $result = Set-CIisHttpHeader -SiteName $script:siteName -Name $name -Value $newValue
        $result | Should -BeNullOrEmpty

        $header = Get-CIisHttpHeader -SiteName $script:siteName -Name $name
        $header | Should -Not -BeNullOrEmpty
        $header.Name | Should -Be $name
        $header.Value | Should -Be $newValue
    }

    It 'should set header on path' {
        $name = 'X-Carbon-SetIisHttpHeader'

        $value = 'Parent'
        Set-CIisHttpHeader -SiteName $script:siteName -Name $name -Value $value

        $subValue = 'Child'
        Set-CIisHttpHeader -LocationPath ($script:siteName, 'SubFolder' | Join-CIisVirtualPath) `
                           -Name $name `
                           -Value $subValue

        $header = Get-CIisHttpHeader -SiteName $script:siteName -Name $name
        $header | Should -Not -BeNullOrEmpty
        $header.Name | Should -Be $name
        $header.Value | Should -Be $value

        $header = Get-CIisHttpHeader -LocationPath ($script:siteName, 'SubFolder' | Join-CIisVirtualPath) -Name $name
        $header | Should -Not -BeNullOrEmpty
        $header.Name | Should -Be $name
        $header.Value | Should -Be $subValue
    }

    It 'should support what if()' {
        $name = 'X-Carbon-SetIisHttpHeader'
        $value = 'Brownies'
        $header = Get-CIisHttpHeader -SiteName $script:siteName -Name $name
        $header | Should -BeNullOrEmpty
        Set-CIisHttpHeader -SiteName $script:siteName -Name $name -Value $value -WhatIf
        $header = Get-CIisHttpHeader -SiteName $script:siteName -Name $name
        $header | Should -BeNullOrEmpty
    }

}
