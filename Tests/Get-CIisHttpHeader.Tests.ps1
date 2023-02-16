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
    $script:siteName = 'CarbonGetIisHttpHeader'
    $script:sitePort = 47939
}

Describe 'Get-CIisHttpHeader' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:siteName -Path $script:testDir -Binding "http/*:$($script:sitePort):*"
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should return all headers' {
        [Object[]] $currentHeaders = Get-CIisHttpHeader -SiteName $script:siteName

        Set-CIisHttpHeader -SiteName $script:siteName -Name 'X-Carbon-Header1' -Value 'Value1'
        Set-CIisHttpHeader -SiteName $script:siteName -Name 'X-Carbon-Header2' -Value 'Value2'

        $newHeaders = Get-CIisHttpHeader -SiteName $script:siteName
        $newHeaders | Should -Not -BeNullOrEmpty
        $newHeaders | Should -HaveCount ($currentHeaders.Count + 2)
    }

    It 'should allow searching by wildcard' {
        $name = 'X-Carbon-GetIisHttpRedirect'
        $value = [Guid]::NewGuid()
        Set-CIisHttpHeader -SiteName $script:siteName -Name $name -Value $value

        ($name, 'X-Carbon*' ) | ForEach-Object {
            $header = Get-CIisHttpHeader -SiteName $script:siteName -Name $_
            $header | Should -Not -BeNullOrEmpty
            $header.Name | Should -Be $name
            $header.Value | Should -Be $value
        }

        $header = Get-CIisHttpHeader -SiteName $script:siteName -Name 'blah*'
        $header | Should -BeNullOrEmpty
    }

}
