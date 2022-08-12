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

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:port = 9879
    $script:siteName = 'TestEnableIisDirectoryBrowsing'
    $script:vDirName = 'VDir'

    function ThenDirectoryBrowsingEnabled
    {
        param(
            [String] $UnderVirtualPath
        )

        $url = "http://localhost:$($script:port)/"
        $expectedContent = $script:testDir
        if( $UnderVirtualPath )
        {
            $url = '{0}{1}' -f $url,$UnderVirtualPath
            $expectedContent = Join-Path -Path $TestDrive -ChildPath $UnderVirtualPath
        }

        $section = Get-CIisConfigurationSection -SiteName $script:siteName `
                                                -SectionPath 'system.webServer/directoryBrowse' `
                                                -VirtualPath $UnderVirtualPath
        $section['enabled'] | Should -BeTrue
        ThenUrlContent $url -Is $expectedContent
    }
}


Describe 'Enable-CIisDirectoryBrowsing' {
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name $script:siteName
    }

    AfterAll {
        Uninstall-CIisAppPool -Name $script:siteName
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:siteName `
                            -Path $script:testDir `
                            -Bindings "http://*:$script:port" `
                            -AppPoolName $script:siteName
        $script:testDir | Set-Content -Path (Join-Path -Path $script:testDir -ChildPath 'index.html') -NoNewLine
        $script:webConfigPath = Join-Path -Path $script:testDir -ChildPath 'web.config'
        if( Test-Path $script:webConfigPath )
        {
            Remove-Item $script:webConfigPath
        }
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should enable directory browsing' {
        Enable-CIisDirectoryBrowsing -SiteName $script:siteName
        ThenDirectoryBrowsingEnabled
    }

    It 'should turn on directory browsing under virtual directory' {
        $vdirRoot = Join-Path -Path $TestDrive -ChildPath 'One'
        New-Item -Path $vdirRoot -ItemType 'Directory'
        (Join-Path -Path $TestDrive -ChildPath $script:vDirName) |
            Set-Content -Path (Join-Path -Path $vdirRoot -ChildPath 'index.html') -NoNewline
        Install-CIisVirtualDirectory -SiteName $script:siteName -Name $script:vDirName -Path $vdirRoot
        Enable-CIisDirectoryBrowsing -SiteName $script:siteName -Path $script:vDirName

        $script:webConfigPath | Should -Not -Exist
        ThenDirectoryBrowsingEnabled -UnderVirtualPath $script:vDirName
    }
}
