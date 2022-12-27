
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:appPoolName = ''
    $script:testNum = 0
    $script:testStartedAt = [DateTime]::MaxValue
    $script:port = 0
    $script:siteUrl = ''

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
                            -Binding (New-Binding -Port $script:port) `
                            -ServerAutoStart $true
        $appPool = Get-CIisAppPool -Name $Named
        if ($IsStarted)
        {
            $state = $appPool.Start()
            $state | Should -Be 'Started'
            Invoke-WebRequest $script:siteUrl | Out-Null
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

        Invoke-WebRequest $script:siteUrl | Out-Null

        Reset-CIisServerManager

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
        $script:port = New-Port
        $script:siteUrl = "http://localhost:$($script:port)"
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
