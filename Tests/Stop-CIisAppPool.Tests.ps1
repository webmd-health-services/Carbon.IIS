
using namespace Microsoft.Web.Administration

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0
    $script:timeoutStart = $false
    $script:workerProcessPid = 0
    $script:stopProcessFails = $false

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

        $appPool = Install-CIisAppPool -Name $Named -ManagedRuntimeVersion 'v4.0' -PassThru
        if ($IsStarted)
        {
            $state = $appPool.Start()
            $state | Should -Be ([ObjectState]::Started)
        }
        elseif ($IsStopped)
        {
            $state = $appPool.Stop()
            $state | Should -Be ([ObjectState]::Stopped)
        }
    }

    function GivenAppPoolTimesOutStopping
    {
        param(
            [Parameter(Mandatory)]
            [int] $WithWorkerProcessPid
        )
        $script:timeoutStart = $true
        $script:workerProcessPid = $WithWorkerProcessPid
    }

    function GivenWorkerProcessFailsToStop
    {
        param(
            [Parameter(Mandatory)]
            [int] $WithWorkerProcessPid
        )

        $script:workerProcessPid = $WithWorkerProcessPid
        $script:stopProcessFails = $true
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

        $Global:Error | Should -Match $MatchesRegex
    }

    function ThenWorkerProcess
    {
        param(
            [int] $ProcessId,

            [switch] $Not,

            [switch] $Stopped
        )

        if ($Not)
        {
            Assert-MockCalled -CommandName 'Get-Process' -ModuleName 'Carbon.IIS' -Times 0
            Assert-MockCalled -CommandName 'Stop-Process' -ModuleName 'Carbon.IIS' -Times 0
            return
        }

        Assert-MockCalled -CommandName 'Get-Process' -ModuleName 'Carbon.IIS' -Times 1
        Assert-MockCalled -CommandName 'Stop-Process' -ModuleName 'Carbon.IIS' -Times 1

    }

    function WhenStarting
    {
        [CmdletBinding()]
        param(
            [Parameter(Position=0)]
            [String] $AppPoolNamed,

            [Parameter(ValueFromPipeline)]
            [Object] $InputObject,

            [hashtable] $WithArgs = @{}
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
                                State = [ObjectState]::Stopping
                                WorkerProcesses = @(
                                    [pscustomobject]@{ ProcessId = $script:workerProcessPid }
                                );
                            }
                            $mockAppPool |
                                Add-Member -Name 'Stop' -MemberType ScriptMethod -Value { return [ObjectState]::Stopping }
                            return $mockAppPool
                        }

                Mock -CommandName 'Get-Process' `
                     -ModuleName 'Carbon.IIS' `
                     -ParameterFilter { $Id -eq $script:workerProcessPid } `
                     -MockWith {
                            if ($script:stopProcessFails)
                            {
                                return [pscustomobject]@{ Id = $Id }
                            }

                            Microsoft.PowerShell.Management\Get-Process -Id -1 `
                                                                        -ErrorAction $PesterBoundParameters['ErrorAction']
                        }

                Mock -CommandName 'Stop-Process' `
                     -ModuleName 'Carbon.IIS' `
                     -ParameterFilter { $Id -eq $script:workerProcessPid -and $Force }
            }

            if ($InputObject)
            {
                $InputObject | Stop-CIisAppPool -Timeout '00:00:01' @WithArgs -ErrorAction $ErrorActionPreference
            }
            else
            {
                Stop-CIisAppPool -Name $AppPoolNamed -Timeout '00:00:01' @WithArgs -ErrorAction $ErrorActionPreference
            }
        }
    }
}

Describe 'Stop-CIisAppPool' {
    BeforeEach {
        $Global:Error.Clear()
        $script:appPoolName = "Stop-CIisAppPool$($script:testNum)"
        $script:testNum++
        $script:timeoutStart = $false
        $script:workerProcessPid = 0
        $script:stopProcessFails = $false
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should stop a started app pool' {
        GivenAppPool $script:appPoolName -IsStarted
        WhenStarting $script:appPoolName
        ThenAppPool $script:appPoolName -IsStopped
    }

    It 'should do nothing to an already stopped app pool' {
        GivenAppPool $script:appPoolName -IsStopped
        WhenStarting $script:appPoolName
        ThenAppPool $script:appPoolName -IsStopped
    }

    It 'should stop waiting to stop app pool' {
        GivenAppPool $script:appPoolName -IsStarted
        GivenAppPoolTimesOutStopping -WithWorkerProcessPid -616
        WhenStarting $script:appPoolName -ErrorAction SilentlyContinue
        ThenAppPool $script:appPoolName -IsStarted
        ThenWorkerProcess -616 -Not -Stopped
        ThenError -MatchesRegex 'failed to stop'
    }

    It 'should kill worker process if stop times out' {
        GivenAppPool $script:appPoolName -IsStarted
        GivenAppPoolTimesOutStopping -WithWorkerProcessPid -617
        WhenStarting $script:appPoolName -WithArgs @{ Force = $true }
        ThenAppPool $script:appPoolName -IsStarted
        ThenWorkerProcess -617 -Stopped
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should stop waiting for killed worker process to exit' {
        GivenAppPool $script:appPoolName -IsStarted
        GivenAppPoolTimesOutStopping -WithWorkerProcessPid -618
        GivenWorkerProcessFailsToStop -618
        WhenStarting $script:appPoolName -WithArgs @{ Force = $true } -ErrorAction SilentlyContinue
        ThenAppPool $script:appPoolName -IsStarted
        ThenWorkerProcess -618 -Stopped
        ThenError -MatchesRegex 'worker process -618 also failed to stop'
    }

    It 'should accept application pool objects from the pipeline' {
        GivenAppPool $script:appPoolName -IsStarted
        Get-CIisAppPool -Name $script:appPoolName | WhenStarting
        ThenAppPool $script:appPoolName -IsStopped
    }

    It 'should accept application pool names from the pipeline' {
        GivenAppPool $script:appPoolName -IsStarted
        $script:appPoolName | WhenStarting
        ThenAppPool $script:appPoolName -IsStopped
    }
}
