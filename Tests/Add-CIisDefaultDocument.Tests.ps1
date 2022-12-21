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
    Write-Debug 'BeforeAll'
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:siteName = 'DefaultDocument'
    $script:sitePort = 4387
    $script:webConfigPath = $null

    function Assert-DefaultDocumentReturned
    {
        ThenUrlContent "http://localhost:$($script:sitePort)/" -Is $PSCommandPath
    }
}

Describe 'Add-CIisDefaultDocument' {
    BeforeAll {
        Write-Debug 'BeforeAll'
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name $script:siteName
    }

    AfterAll {
        Uninstall-CIisAppPool -Name $script:siteName
        Complete-W3ServiceTestFixture
        Write-Debug 'AfterAll'
    }

    BeforeEach {
        Write-Debug 'BeforeEach'
        $script:testDir = New-TestDirectory
        Uninstall-CIisWebsite $script:siteName
        Install-CIisWebsite -Name $script:siteName `
                            -Path $script:testDir `
                            -Bindings "http://*:$($script:sitePort)" `
                            -AppPoolName $script:siteName
        $PSCommandPath | Set-Content -Path (Join-Path -Path $script:testDir -ChildPath 'newdefault.html') -NoNewLine

        $script:webConfigPath = Join-Path -Path $script:testDir -ChildPath 'web.config'
        if( Test-Path $script:webConfigPath -PathType Leaf )
        {
            Remove-Item $script:webConfigPath
        }

        $Global:Error.Clear()
        Write-Debug 'It'
    }

    AfterEach {
        Write-Debug 'BeforeEach'
        Uninstall-CIisWebsite $script:siteName
    }

    It 'should add default document' {
        Add-CIISDefaultDocument -Site $script:SiteName -FileName 'newdefault.html'
        Assert-DefaultDocumentReturned
        $script:webConfigPath | Should -Not -Exist
    }

    It 'should add default document twice' {
        Add-CIISDefaultDocument -Site $script:SiteName -FileName 'newdefault.html'
        Add-CIISDefaultDocument -Site $script:SiteName -FileName 'newdefault.html'
        $Global:Error | Should -BeNullOrEmpty
        $section =
            Get-CIisConfigurationSection -LocationPath $script:SiteName -SectionPath 'system.webServer/defaultDocument'
        $section | Should -Not -BeNullOrEmpty
        ($section.GetCollection('files') | Where-Object { $_['value'] -eq 'newdefault.html' }) | Should -BeOfType ([Microsoft.Web.Administration.ConfigurationElement])
        Assert-DefaultDocumentReturned
    }
}
