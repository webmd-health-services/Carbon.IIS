
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:appPoolName = ''
    $script:testNum = 0
    $script:testStartedAt = [DateTime]::MaxValue
    $script:port = 6166
    $script:siteUrl = "http://localhost:$($script:port)"

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

        Install-CIisAppPool -Name $Named `
                            -ManagedRuntimeVersion 'v4.0' `
                            -AutoStart $true `
                            -StartMode AlwaysRunning `
                            -PassThru
        Install-CIIsWebsite -Name $script:appPoolName `
                            -PhysicalPath 'C:\inetpub\wwwroot' `
                            -AppPoolName $Named `
                            -Binding "http/*:$($script:port)" `
                            -ServerAutoStart $true
        if ($IsStarted)
        {
            Start-CIisAppPool -Name $Named
            $expectedState = 'Started'
            Invoke-WebRequest $script:siteUrl | Out-Null
        }
        elseif ($IsStopped)
        {
            Stop-CIisAppPool -Name $Named
            $expectedState = 'Stopped'
        }
        $appPool = Get-CIisAppPool -Name $Named
        $appPool | Should -Not -BeNullOrEmpty
        $appPool.State | Should -Be $expectedState

        if ($isStarted)
        {
            $appPool.WorkerProcesses | Should -Not -BeNullOrEmpty
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

        Invoke-WebRequest $script:siteUrl | Out-Null

        $appPool = Get-CIisAppPool -Name $Named
        $appPool | Should -Not -BeNullOrEmpty
        $appPool.State | Should -Be 'Started'
        $appPool.WorkerProcesses |
            ForEach-Object { Get-Process -Id $_.ProcessId } |
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

    It 'should restart started application pool' {
        GivenAppPool $script:appPoolName -IsStarted
        WhenRestarting $script:appPoolName
        ThenAppPool $script:appPoolName -Restarted
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should start a stopped application pool' {
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
