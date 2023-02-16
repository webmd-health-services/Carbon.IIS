
using namespace Microsoft.Web.Administration

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0
    $script:timeoutStart = $false

    function GivenAppPool
    {
        param(
            [Parameter(Position=0)]
            [String] $Named,

            [Parameter(ParameterSetName='EnsureStartedpped')]
            [switch] $IsStarted,

            [Parameter(ParameterSetName='EnsureStopped')]
            [switch] $IsStopped
        )

        Install-CIisAppPool -Name $Named -ManagedRuntimeVersion 'v4.0'
        if ($IsStarted)
        {
            Start-CIisAppPool -Name $Named
            $expectedState = [ObjectState]::Started
        }
        elseif ($IsStopped)
        {
            Stop-CIisAppPool -Name $Named
            $expectedState = [ObjectState]::Stopped
        }
        Get-CIisAppPool -Name $Named | Select-Object -ExpandProperty 'State' | Should -Be $expectedState
    }

    function GivenAppPoolTimesOutStarting
    {
        $script:timeoutStart = $true
    }

    function ThenAppPool
    {
        param(
            [String] $Named,

            [switch] $IsStarted,

            [switch] $IsStopped
        )

        $appPool = Get-CIisAppPool -Name $Named
        $appPool | Should -Not -BeNullOrEmpty

        if ($IsStarted)
        {
            $appPool.State | Should -Be ([ObjectState]::Started)
        }

        if ($IsStopped)
        {
            $appPool.State | Should -Be ([ObjectSTate]::Stopped)
        }
    }

    function ThenError
    {
        param(
            [String] $MatchesRegex
        )

        $Global:Error | Format-List * -Force | Out-String | Write-Debug
        $Global:Error | Should -Match $MatchesRegex
    }

    function WhenStarting
    {
        [CmdletBinding()]
        param(
            [String] $AppPoolNamed,

            [Parameter(ValueFromPipeline)]
            [Object] $InputObject
        )

        process
        {
            if ($script:timeoutStart)
            {
                Mock -CommandName 'Get-CIisAppPool' `
                    -ModuleName 'Carbon.IIS' `
                    -ParameterFilter { $Name -eq $AppPoolNamed } `
                    -MockWith {
                            $mockAppPool = [pscustomobject]@{
                                Name = $AppPoolNamed;
                                State = [ObjectState]::Starting
                            }
                            $mockAppPool |
                                Add-Member -Name 'Start' -MemberType ScriptMethod -Value { return [ObjectState]::Starting }
                            return $mockAppPool
                        }
            }

            if ($InputObject)
            {
                $InputObject | Start-CIisAppPool -Timeout '00:00:01' -ErrorAction $ErrorActionPreference
            }
            else
            {
                Start-CIisAppPool -Name $AppPoolNamed -Timeout '00:00:01' -ErrorAction $ErrorActionPreference
            }
        }
    }
}

AfterAll {
}

Describe 'Start-CIisAppPool' {
    BeforeEach {
        $Global:Error.Clear()
        $script:appPoolName = "Start-CIisAppPool$($script:testNum)"
        $script:testNum++
        $script:timeoutStart = $false
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should start a stopped application pool' {
        GivenAppPool $script:appPoolName -IsStopped
        WhenStarting $script:appPoolName
        ThenAppPool $script:appPoolName -IsStarted
    }

    It 'should do nothing to an already started application pool' {
        GivenAppPool $script:appPoolName -IsStarted
        WhenStarting $script:appPoolName
        ThenAppPool $script:appPoolName -IsStarted
    }

    It 'should stop waiting to start application pool' {
        GivenAppPool $script:appPoolName -IsStopped
        GivenAppPoolTimesOutStarting $script:appPoolName
        WhenStarting $script:appPoolName -ErrorAction SilentlyContinue
        ThenAppPool $script:appPoolName -IsStopped
        ThenError -MatchesRegex 'failed to start'
    }

    It 'should accept application pool objects from the pipeline' {
        GivenAppPool $script:appPoolName -IsStopped
        Get-CIisAppPool -Name $script:appPoolName | WhenStarting
        ThenAppPool $script:appPoolName -IsStarted
    }

    It 'should accept application pool names from the pipeline' {
        GivenAppPool $script:appPoolName -IsStopped
        $script:appPoolName | WhenStarting
        ThenAppPool $script:appPoolName -IsStarted
    }
}
