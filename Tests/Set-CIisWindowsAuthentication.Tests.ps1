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
    $script:siteName = 'Windows Authentication'
    $script:sitePort = 4387

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    function Assert-WindowsAuthentication($VirtualPath = '', [bool]$KernelMode)
    {
        $authSettings = Get-CIisSecurityAuthentication -SiteName $script:SiteName -VirtualPath $VirtualPath -Windows
        $KernelMode | Should -Be ($authSettings.GetAttributeValue( 'useKernelMode' ))
    }
}

Describe 'Set-CIisWindowsAuthentication' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testWebRoot = New-TestDirectory
        Uninstall-CIisWebsite $script:siteName
        Install-CIisWebsite -Name $script:siteName -Path $script:testWebRoot -Bindings "http://*:$script:sitePort"
        $script:webConfigPath = Join-Path -Path $script:testWebRoot -ChildPath 'web.config'
        if( Test-Path $script:webConfigPath -PathType Leaf )
        {
            Remove-Item $script:webConfigPath
        }
    }

    AfterEach {
        Uninstall-CIisWebsite $script:siteName
    }

    It 'should enable windows authentication' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName
        Assert-WindowsAuthentication -KernelMode $true
        $script:webConfigPath | Should -Not -Exist
    }

    It 'should enable kernel mode' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName
        Assert-WindowsAuthentication -KernelMode $true
    }

    It 'set windows authentication on sub folders' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName -VirtualPath 'SubFolder'
        Assert-WindowsAuthentication -VirtualPath SubFolder -KernelMode $true
    }

    It 'should disable kernel mode' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName -DisableKernelMode
        Assert-WindowsAuthentication -KernelMode $false
    }

    It 'should support what if' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName
        Assert-WindowsAuthentication -KernelMode $true
        Set-CIisWindowsAuthentication -SiteName $script:siteName -WhatIf -DisableKernelMode
        Assert-WindowsAuthentication -KernelMode $true
    }
}
