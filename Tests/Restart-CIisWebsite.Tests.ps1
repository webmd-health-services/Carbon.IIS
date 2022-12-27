
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:websiteName = ''
    $script:testNum = 0
    $script:testStartedAt = [DateTime]::MaxValue
    $script:port = -1
    $script:siteUrl = ''

    function GivenWebsite
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
                            -StartMode AlwaysRunning
        Install-CIIsWebsite -Name $Named `
                            -PhysicalPath 'C:\inetpub\wwwroot' `
                            -AppPoolName $Named `
                            -Binding (New-Binding -Port $script:port) `
                            -ServerAutoStart $true
        $website = Get-CIisWebsite -Name $Named
        if ($IsStarted)
        {
            $state = $website.Start()
            $state | Should -Be 'Started'
            Invoke-WebRequest $script:siteUrl | Out-Null
        }
        elseif ($IsStopped)
        {
            $state = $website.Stop()
            while ($state -ne 'Stopped')
            {
                Start-Sleep -Milliseconds 100
                $state = $website.State
            }
            $state | Should -Be 'Stopped'
        }
    }

    function ThenWebsite
    {
        param(
            [Parameter(Mandatory)]
            [String] $Named,

            [Parameter(Mandatory)]
            [switch] $Restarted
        )

        Invoke-WebRequest $script:siteUrl | Out-Null

        $website = Get-CIisWebsite -Name $Named
        $website | Should -Not -BeNullOrEmpty
        $website.State | Should -Be 'Started'
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
            [String] $WebsiteNamed,

            [Parameter(ValueFromPipeline)]
            [Object] $InputObject,

            [hashtable] $WithArgs = @{}
        )

        process
        {
            if ($InputObject)
            {
                $InputObject | Restart-CIisWebsite @WithArgs -ErrorAction $ErrorActionPreference
            }
            else
            {
                Restart-CIisWebsite -Name $WebsiteNamed @WithArgs -ErrorAction $ErrorActionPreference
            }
        }
    }
}

Describe 'Restart-CIisWebsite' {
    BeforeEach {
        $Global:Error.Clear()
        $script:websiteName = "Restart-CIisWebsite$($script:testNum)"
        $script:testNum++
        $script:port = New-Port
        $script:siteUrl = "http://localhost:$($script:port)"
        $script:testStartedAt = Get-Date
    }

    AfterEach {
        Uninstall-CIIsWebsite -Name $script:websiteName
        Uninstall-CIisAppPool -Name $script:websiteName
    }

    It 'should restart started website' {
        GivenWebsite $script:websiteName -IsStarted
        WhenRestarting $script:websiteName
        ThenWebsite $script:websiteName -Restarted
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should start a stopped website' {
        GivenWebsite $script:websiteName -IsStopped
        WhenRestarting $script:websiteName
        ThenWebsite $script:websiteName -Restarted
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should accept website objects from the pipeline' {
        GivenWebsite $script:websiteName -IsStarted
        Get-CIisWebsite -Name $script:websiteName | WhenRestarting
        ThenWebsite $script:websiteName -Restarted
    }

    It 'should accept website names from the pipeline' {
        GivenWebsite $script:websiteName -IsStarted
        $script:websiteName | WhenRestarting
        ThenWebsite $script:websiteName -Restarted
    }
}
