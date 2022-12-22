
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:appPoolName = ''
    $script:testNum = 0
    $script:testStartedAt = [DateTime]::MaxValue

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

        $appPool = Install-CIisAppPool -Name $Named `
                                       -ManagedRuntimeVersion 'v4.0' `
                                       -AutoStart $true `
                                       -StartMode AlwaysRunning `
                                       -PassThru
        Install-CIIsWebsite -Name $script:appPoolName `
                            -PhysicalPath 'C:\inetpub\wwwroot' `
                            -AppPoolName $Named `
                            -Binding 'http/*:6166' `
                            -ServerAutoStart $true
        $appPool = Get-CIisAppPool -Name $Named
        if ($IsStarted)
        {
            $state = $appPool.Start()
            $state | Should -Be 'Started'
            Invoke-WebRequest 'http://localhost:6166' | Out-Null
            $appPool.WorkerProcesses | Should -Not -BeNullOrEmpty
        }
        elseif ($IsStopped)
        {
            $state = $appPool.Stop()
            while ($state -ne 'Stopped')
            {
                Start-Sleep -Milliseconds 100
                $state = $appPool.State
            }
            $state | Should -Be 'Stopped'
        }
    }

    function ThenAppPool
    {
        param(
            [Parameter(Mandatory)]
            [String] $Named,

            [Parameter(Mandatory)]
            [switch] $Restarted
        )

        Invoke-WebRequest 'http://localhost:6166' | Out-Null

        $appPool = Get-CIisAppPool -Name $Named
        $appPool | Should -Not -BeNullOrEmpty

        $appPool.State | Should -Be 'Started'
        $appPool.WorkerProcesses |
            Add-Member -Name 'Id' -MemberType AliasProperty -Value 'ProcessId' -PassThru |
            Get-Process |
            Select-Object -ExpandProperty 'StartTime' |
            Should -BeGreaterThan $script:testStartedAt
    }

    function ThenError
    {
        param(
            [String] $MatchesRegex
        )

        $Global:Error | Should -Match $MatchesRegex
    }

    function WhenRestarting
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
            if ($InputObject)
            {
                $InputObject | Restart-CIisAppPool @WithArgs -ErrorAction $ErrorActionPreference
            }
            else
            {
                Restart-CIisAppPool -Name $AppPoolNamed @WithArgs -ErrorAction $ErrorActionPreference
            }
        }
    }
}

Describe 'Restart-CIisAppPool' {
    BeforeEach {
        $Global:Error.Clear()
        $script:appPoolName = "Restart-CIisAppPool$($script:testNum)"
        $script:testNum++
        $script:testStartedAt = Get-Date
    }

    AfterEach {
        Uninstall-CIIsWebsite -Name $script:appPoolName
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should restart started app pool' {
        GivenAppPool $script:appPoolName -IsStarted
        WhenRestarting $script:appPoolName
        ThenAppPool $script:appPoolName -Restarted
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should start a stopped app pool' {
        GivenAppPool $script:appPoolName -IsStopped
        WhenRestarting $script:appPoolName
        ThenAppPool $script:appPoolName -Restarted
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should accept application pool objects from the pipeline' {
        GivenAppPool $script:appPoolName -IsStarted
        Get-CIisAppPool -Name $script:appPoolName | WhenRestarting
        ThenAppPool $script:appPoolName -Restarted
    }

    It 'should accept application pool names from the pipeline' {
        GivenAppPool $script:appPoolName -IsStarted
        $script:appPoolName | WhenRestarting
        ThenAppPool $script:appPoolName -Restarted
    }
}
