
using namespace Microsoft.Web.Administration

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:websiteName = ''
    $script:testNum = 0
    $script:timeoutStart = $false

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

        Install-CIisAppPool -Name $Named -ManagedRuntimeVersion 'v4.0' -PassThru
        Install-CIIsWebsite -Name $Named `
                            -PhysicalPath 'C:\inetpub\wwwroot' `
                            -AppPoolName $Named `
                            -Binding (New-Binding) `
                            -ServerAutoStart $true
        if ($IsStarted)
        {
            Start-CIisWebsite -Name $Named
            $expectedState = 'Started'
        }
        elseif ($IsStopped)
        {
            Stop-CIisWebsite -Name $Named
            $expectedState = 'Stopped'
        }
        Get-CIisWebsite -Name $Named | ForEach-Object -MemberName 'State' | Should -Be $expectedState
    }

    function GivenWebsiteTimesOutStarting
    {
        $script:timeoutStart = $true
    }

    function ThenWebsite
    {
        param(
            [String] $Named,

            [switch] $IsStarted,

            [switch] $IsStopped
        )

        $website = Get-CIisWebsite -Name $Named
        $website | Should -Not -BeNullOrEmpty

        if ($IsStarted)
        {
            $website.State | Should -Be ([ObjectState]::Started)
        }

        if ($IsStopped)
        {
            $website.State | Should -Be ([ObjectSTate]::Stopped)
        }
    }

    function ThenError
    {
        param(
            [String] $MatchesRegex
        )

        $Global:Error | Should -Match $MatchesRegex
    }

    function WhenStarting
    {
        [CmdletBinding()]
        param(
            [String] $WebsiteNamed,

            [Parameter(ValueFromPipeline)]
            [Object] $InputObject
        )

        process
        {
            if ($script:timeoutStart)
            {
                Mock -CommandName 'Get-CIisWebsite' `
                     -ModuleName 'Carbon.IIS' `
                     -ParameterFilter { $Name -eq $WebsiteNamed } `
                     -MockWith {
                            $mockWebsite = [pscustomobject]@{
                                Name = $WebsiteNamed;
                                State = [ObjectState]::Starting;
                                Applications = [pscustomobject]@{
                                    Path = '/';
                                    ApplicationPoolName = $WebsiteNamed;
                                }
                            }
                            $mockWebsite |
                                Add-Member -Name 'Start' -MemberType ScriptMethod -Value { return [ObjectState]::Starting }
                            return $mockWebsite
                        }
            }

            if ($InputObject)
            {
                $InputObject | Start-CIisWebsite -Timeout '00:00:01' -ErrorAction $ErrorActionPreference
            }
            else
            {
                Start-CIisWebsite -Name $WebsiteNamed -Timeout '00:00:01' -ErrorAction $ErrorActionPreference
            }
        }
    }
}

AfterAll {
}

Describe 'Start-CIisWebsite' {
    BeforeEach {
        $Global:Error.Clear()
        $script:websiteName = "Start-CIisWebsite$($script:testNum)"
        $script:testNum++
        $script:timeoutStart = $false
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:websiteName
        Uninstall-CIisAppPool -Name $script:websiteName
    }

    It 'should start a stopped website' {
        GivenWebsite $script:websiteName -IsStopped
        WhenStarting $script:websiteName
        ThenWebsite $script:websiteName -IsStarted
    }

    It 'should do nothing to an already started website' {
        GivenWebsite $script:websiteName -IsStarted
        WhenStarting $script:websiteName
        ThenWebsite $script:websiteName -IsStarted
    }

    It 'should stop waiting to start website' {
        GivenWebsite $script:websiteName -IsStopped
        GivenWebsiteTimesOutStarting $script:websiteName
        WhenStarting $script:websiteName -ErrorAction SilentlyContinue
        ThenWebsite $script:websiteName -IsStopped
        ThenError -MatchesRegex 'failed to start'
    }

    It 'should accept website objects from the pipeline' {
        GivenWebsite $script:websiteName -IsStopped
        Get-CIisWebsite -Name $script:websiteName | WhenStarting
        ThenWebsite $script:websiteName -IsStarted
    }

    It 'should accept website names from the pipeline' {
        GivenWebsite $script:websiteName -IsStopped
        $script:websiteName | WhenStarting
        ThenWebsite $script:websiteName -IsStarted
    }
}
