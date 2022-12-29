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
    $script:testNum = 0

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    function Assert-WindowsAuthentication
    {
        param(
            $VirtualPath = '',
            [bool] $AuthPersistNonNTLM = $true,
            [bool] $AuthPersistSingleRequest = $false,
            [bool] $Enabled = $false,
            [bool] $UseKernelMode = $true
        )
        $authSettings =
            Get-CIisSecurityAuthentication -LocationPath (Join-CIisPath -Path $script:SiteName, $VirtualPath) `
                                           -Windows
        $authSettings.GetAttributeValue('authPersistNonNTLM') | Should -Be $AuthPersistNonNTLM
        $authSettings.GetAttributeValue('authPersistSingleRequest') | Should -Be $AuthPersistSingleRequest
        $authSettings.GetAttributeValue('enabled') | Should -Be $Enabled
        $authSettings.GetAttributeValue('useKernelMode') | Should -Be $UseKernelMode
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
        $script:siteName = "$($PSCommandPath | Split-Path -Leaf)$($script:testNum)"
        $script:testNum += 1

        Install-CIisWebsite -Name $script:siteName -Path $script:testWebRoot -Bindings (New-Binding)
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
        Assert-WindowsAuthentication -UseKernelMode $true
        $script:webConfigPath | Should -Not -Exist
    }

    It 'should enable kernel mode' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName -UseKernelMode $true
        Assert-WindowsAuthentication -UseKernelMode $true
    }

    It 'set windows authentication on sub folders' {
        Set-CIisWindowsAuthentication -LocationPath (Join-CIisPath -Path $script:siteName, 'SubFolder')
        Assert-WindowsAuthentication -VirtualPath SubFolder -UseKernelMode $true
    }

    It 'should disable kernel mode' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName -UseKernelMode $false
        Assert-WindowsAuthentication -UseKernelMode $false
    }

    It 'should support what if' {
        Set-CIisWindowsAuthentication -SiteName $script:siteName
        Assert-WindowsAuthentication -UseKernelMode $true
        Set-CIisWindowsAuthentication -SiteName $script:siteName -WhatIf -UseKernelMode $false
        Assert-WindowsAuthentication -UseKernelMode $true
    }

    It 'should reset values to defaults' {
        $defaults =
            Get-CIisConfigurationSection -SectionPath 'system.webServer/security/authentication/windowsAuthentication'

        $setArgs = @{
            AuthPersistNonNTLM = (-not $defaults.GetAttributeValue('authPersistNonNtlm'));
            AuthPersistSingleRequest = (-not $defaults.GetAttributeValue('authPersistSingleRequest'));
            Enabled = (-not $defaults.GetAttributeValue('enabled'));
            UseAppPoolCredentials = (-not $defaults.GetAttributeValue('useAppPoolCredentials'));
            UseKernelMode = (-not $defaults.GetAttributeValue('useKernelMode'));
        }
        Set-CIisWindowsAuthentication -LocationPath $script:siteName @setArgs
        Assert-WindowsAuthentication @setArgs

        Set-CIisWindowsAuthentication -LocationPath $script:siteName -Reset

        $setArgs = @{
            AuthPersistNonNTLM = -not $setArgs['authPersistNonNtlm'];
            AuthPersistSingleRequest = -not $setArgs['authPersistSingleRequest'];
            Enabled = -not $setArgs['enabled'];
            UseAppPoolCredentials = -not $setArgs['useAppPoolCredentials'];
            UseKernelMode = -not $setArgs['useKernelMode'];
        }
        Assert-WindowsAuthentication @setArgs
    }
}
