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
    $script:appPoolName = 'CarbonInstallIisAppPool'
    $script:username = 'CarbonInstallIisAppP'
    $script:password = '!QAZ2wsx8fk3'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    Start-W3ServiceTestFixture

    $script:credential = New-CCredential -Username $script:username -Password $script:password
    Install-CUser -Credential $script:credential `
                  -Description 'User for testing Carbon''s Install-CIisAppPool function.'

    function Assert-AppPoolExists
    {
        $exists = Test-CIisAppPool -Name $script:appPoolname
        $exists | Should -BeTrue
    }

    function Assert-ManagedRuntimeVersion($Version)
    {
        $apppool = Get-CIisAppPool -Name $script:appPoolName
        $apppool.ManagedRuntimeVersion | Should -Be $Version
    }

    function Assert-ManagedPipelineMode($expectedMode)
    {
        $apppool = Get-CIisAppPool -Name $script:appPoolName
        $apppool.ManagedPipelineMode | Should -Be $expectedMode
    }

    function Assert-IdentityType($expectedIdentityType)
    {
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool.ProcessModel.IdentityType | Should -Be $expectedIdentityType
    }

    function Assert-IdleTimeout($expectedIdleTimeout)
    {
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $expectedIdleTimeoutTimespan = New-TimeSpan -minutes $expectedIdleTimeout
        $appPool.ProcessModel.IdleTimeout | Should -Be $expectedIdleTimeoutTimespan
    }

    function Assert-Identity($expectedUsername, $expectedPassword)
    {
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool.ProcessModel.UserName | Should -Be $expectedUsername
        $appPool.ProcessModel.Password | Should -Be $expectedPassword
    }

    function Assert-AppPool32BitEnabled([bool]$expected32BitEnabled)
    {
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool.Enable32BitAppOnWin64 | Should -Be $expected32BitEnabled
    }

    function Assert-AppPool
    {
        param(
            [Parameter(Position=0)]
            $AppPool,

            $ManangedRuntimeVersion = 'v4.0',

            [switch] $ClassicPipelineMode,

            $IdentityType = (Get-IISDefaultAppPoolIdentity),

            [switch] $Enable32Bit,

            [TimeSpan] $IdleTimeout = (New-TimeSpan -Seconds 0)
        )

        Assert-AppPoolExists

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
        $AppPool.ProcessModel.IdleTimeout | Should -Be $IdleTimeout

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
        Revoke-CPrivilege -Identity $script:username -Privilege SeBatchLogonRight
    }

    It 'should set managed runtime to nothing' {
        Install-CIisAppPool -Name $script:appPoolName -ManagedRuntimeVersion ''
        Assert-ManagedRuntimeVersion -Version ''
    }

    It 'should create new app pool' {
        $result = Install-CIisAppPool -Name $script:appPoolName -PassThru
        $result | Should -Not -BeNullOrEmpty
        Assert-AppPool $result
    }

    It 'should create new app pool but not return object' {
        $result = Install-CIisAppPool -Name $script:appPoolName
        $result | Should -BeNullOrEmpty
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool | Should -Not -BeNullOrEmpty
        Assert-AppPool $appPool

    }

    It 'should set managed runtime version' {
        $result = Install-CIisAppPool -Name $script:appPoolName -ManagedRuntimeVersion 'v2.0'
        $result | Should -BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v2.0'
    }

    It 'should set managed pipeline mode' {
        $result = Install-CIisAppPool -Name $script:appPoolName -ClassicPipelineMode
        $result | Should -BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedPipelineMode 'Classic'
    }

    It 'should set identity as service account' {
        $result = Install-CIisAppPool -Name $script:appPoolName -ServiceAccount 'NetworkService'
        $result | Should -BeNullOrEmpty
        Assert-AppPoolExists
        Assert-IdentityType 'NetworkService'
    }

    It 'should set identity with credential' {
        $script:credential = New-CCredential -UserName $script:username -Password $script:password
        $script:credential | Should -Not -BeNullOrEmpty
        $result = Install-CIisAppPool -Name $script:appPoolName -Credential $script:credential
        $result | Should -BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Identity $script:credential.UserName $script:credential.GetNetworkCredential().Password
        Assert-IdentityType 'Specificuser'
        Get-CPrivilege $script:username | Where-Object { $_ -eq 'SeBatchLogonRight' } | Should -Not -BeNullOrEmpty
    }

    It 'should set idle timeout' {
        $result = Install-CIisAppPool -Name $script:appPoolName -IdleTimeout 55
        $result | Should -BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Idletimeout 55
    }

    It 'should enable32bit apps' {
        $result = Install-CIisAppPool -Name $script:appPoolName -Enable32BitApps
        $result | Should -BeNullOrEmpty
        Assert-AppPoolExists
        Assert-AppPool32BitEnabled $true
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
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v4.0'
        Assert-ManagedPipelineMode 'Integrated'
        Assert-IdentityType (Get-IISDefaultAppPoolIdentity)

        Assert-AppPool32BitEnabled $false

        $result = Install-CIisAppPool -Name $script:appPoolName -ManagedRuntimeVersion 'v2.0' -ClassicPipeline -ServiceAccount 'LocalSystem' -Enable32BitApps
        $result | Should -BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v2.0'
        Assert-ManagedPipelineMode 'Classic'
        Assert-IdentityType 'LocalSystem'
        Assert-AppPool32BitEnabled $true

    }

    It 'should convert32 bit app poolto64 bit' {
        Install-CIisAppPool -Name $script:appPoolName -ServiceAccount NetworkService -Enable32BitApps
        Assert-AppPool32BitEnabled $true
        Install-CIisAppPool -Name $script:appPoolName -ServiceAccount NetworkService
        Assert-AppPool32BitEnabled $false
    }

    It 'should switch to app pool identity if service account not given' {
        Install-CIisAppPool -Name $script:appPoolName -ServiceAccount NetworkService
        Assert-IdentityType 'NetworkService'
        Install-CIisAppPool -Name $script:appPoolName
        Assert-IdentityType (Get-IISDefaultAppPoolIdentity)
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

    It 'should fail if identity does not exist' {
        $Global:Error.Clear()
        $cred = New-CCredential -UserName 'IDoNotExist' `
                                -Password (ConvertTo-SecureString -String 'blahblah' -AsPlainText -Force)
        Install-CIisAppPool -Name $script:appPoolName -Credential $cred -ErrorAction SilentlyContinue
        (Test-CIisAppPool -Name $script:appPoolName) | Should -BeTrue
        $Global:Error | Should -Match 'Identity ''IDoNotExist'' not found'
    }
}
