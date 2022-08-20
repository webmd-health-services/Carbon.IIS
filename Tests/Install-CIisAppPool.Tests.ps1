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
    $script:appPoolName = 'Install-CIisAppPool'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    function ThenAppPoolExists
    {
        $exists = Test-CIisAppPool -Name $script:appPoolname
        $exists | Should -BeTrue
    }

    function ThenRuntimeVersionIs
    {
        param(
            $Version
        )

        $apppool = Get-CIisAppPool -Name $script:appPoolName
        $apppool.ManagedRuntimeVersion | Should -Be $Version
    }

    function ThenPipelineModeIs
    {
        param(
            $ExpectedMode
        )

        $apppool = Get-CIisAppPool -Name $script:appPoolName
        $apppool.ManagedPipelineMode | Should -Be $expectedMode
    }

    function Then32BitEnabledIs
    {
        param(
            [bool] $Expected32BitEnabled
        )
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool.Enable32BitAppOnWin64 | Should -Be $Expected32BitEnabled
    }

    function ThenAppPool
    {
        param(
            [Parameter(Position=0)]
            $AppPool,

            $ManangedRuntimeVersion = 'v4.0',

            [switch] $ClassicPipelineMode,

            $IdentityType = (Get-IISDefaultAppPoolIdentity),

            [switch] $Enable32Bit
        )

        ThenAppPoolExists

        if( -not $AppPool )
        {
            $AppPool = Get-CIisAppPool -Name $script:appPoolName
        }

        $AppPool.ManagedRuntimeVersion | Should -Be $ManangedRuntimeVersion
        $pipelineMode = 'Integrated'
        if( $ClassicPipelineMode )
        {
            $pipelineMode = 'Classic'
        }
        $AppPool.ManagedPipelineMode | Should -Be $pipelineMode
        $AppPool.ProcessModel.IdentityType | Should -Be $IdentityType
        $AppPool.Enable32BitAppOnWin64 | Should -Be ([bool]$Enable32Bit)

        $MAX_TRIES = 20
        for ( $idx = 0; $idx -lt $MAX_TRIES; ++$idx )
        {
            $AppPool = Get-CIisAppPool -Name $script:appPoolName
            $AppPool | Should -Not -BeNullOrEmpty
            if( $AppPool.State )
            {
                $AppPool.State | Should -Be ([Microsoft.Web.Administration.ObjectState]::Started)
                break
            }
            Start-Sleep -Milliseconds 1000
        }
    }

    function Get-IISDefaultAppPoolIdentity
    {
        $iisVersion = Get-CIISVersion
        if( $iisVersion -eq '7.0' )
        {
            return 'NetworkService'
        }
        return 'ApplicationPoolIdentity'
    }
}

Describe 'Install-CIisAppPool' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should set managed runtime to nothing' {
        Install-CIisAppPool -Name $script:appPoolName
        ThenRuntimeVersionIs -Version 'v4.0'  # The default from application pool defaults.
    }

    It 'should create new app pool' {
        $result = Install-CIisAppPool -Name $script:appPoolName -PassThru
        $result | Should -Not -BeNullOrEmpty
        ThenAppPool $result
    }

    It 'should create new app pool but not return object' {
        $result = Install-CIisAppPool -Name $script:appPoolName
        $result | Should -BeNullOrEmpty
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool | Should -Not -BeNullOrEmpty
        ThenAppPool $appPool

    }

    It 'should set managed runtime version' {
        $result = Install-CIisAppPool -Name $script:appPoolName -ManagedRuntimeVersion 'v2.0'
        $result | Should -BeNullOrEmpty
        ThenAppPoolExists
        ThenRuntimeVersionIs 'v2.0'
    }

    It 'should set managed pipeline mode' {
        $result = Install-CIisAppPool -Name $script:appPoolName -ManagedPipelineMode Classic
        $result | Should -BeNullOrEmpty
        ThenAppPoolExists
        ThenPipelineModeIs 'Classic'
    }

    It 'should enable32bit apps' {
        $result = Install-CIisAppPool -Name $script:appPoolName -Enable32BitAppOnWin64
        $result | Should -BeNullOrEmpty
        ThenAppPoolExists
        Then32BitEnabledIs $true
    }

    It 'should handle app pool that exists' {
        $result = Install-CIisAppPool -Name $script:appPoolName
        $result | Should -BeNullOrEmpty
        $result = Install-CIisAppPool -Name $script:appPoolName
        $result | Should -BeNullOrEmpty
    }

    It 'should change settings on existing app pool' {
        $result = Install-CIisAppPool -Name $script:appPoolName
        $result | Should -BeNullOrEmpty
        ThenAppPoolExists
        ThenRuntimeVersionIs 'v4.0'
        ThenPipelineModeIs 'Integrated'
        Then32BitEnabledIs $false

        $result = Install-CIisAppPool -Name $script:appPoolName `
                                      -ManagedRuntimeVersion 'v2.0' `
                                      -ManagedPipelineMode Classic `
                                      -Enable32BitAppOnWin64
        $result | Should -BeNullOrEmpty
        ThenAppPoolExists
        ThenRuntimeVersionIs 'v2.0'
        ThenPipelineModeIs 'Classic'
        Then32BitEnabledIs $true

    }

    It 'should convert32 bit app poolto64 bit' {
        Install-CIisAppPool -Name $script:appPoolName -Enable32BitAppOnWin64
        Then32BitEnabledIs $true
        Install-CIisAppPool -Name $script:appPoolName
        Then32BitEnabledIs $false
    }

    It 'should start stopped app pool' {
        Install-CIisAppPool -Name $script:appPoolName
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool | Should -Not -BeNullOrEmpty
        if( $appPool.state -ne [Microsoft.Web.Administration.ObjectState]::Stopped )
        {
            Start-Sleep -Seconds 1
            $appPool.Stop()
        }

        Install-CIisAppPool -Name $script:appPoolName
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool.state | Should -Be ([Microsoft.Web.Administration.ObjectState]::Started)
    }
}