
using namespace Microsoft.Web.Administration

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'


BeforeAll {
    Set-StrictMode -Version 'Latest'

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
        Get-CIisWebsite -Name $Named | Select-Object -ExpandProperty 'State' | Should -Be $expectedState
    }

    function GivenWebsiteTimesOutStopping
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

        $Global:Error | Format-List * -Force | Out-String | Write-Debug
        $Global:Error | Should -Match $MatchesRegex
    }

    function WhenStarting
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
            if ($script:timeoutStart)
            {
                Mock -CommandName 'Get-CIisWebsite' `
                     -ModuleName 'Carbon.IIS' `
                     -ParameterFilter { $Name -eq $WebsiteNamed } `
                     -MockWith {
                            $mockWebsite = [pscustomobject]@{
                                Name = $WebsiteNamed;
                                State = [ObjectState]::Stopping
                            }
                            $mockWebsite |
                                Add-Member -Name 'Stop' -MemberType ScriptMethod -Value { return [ObjectState]::Stopping }
                            return $mockWebsite
                        }
            }

            if ($InputObject)
            {
                $InputObject | Stop-CIisWebsite -Timeout '00:00:01' @WithArgs -ErrorAction $ErrorActionPreference
            }
            else
            {
                Stop-CIisWebsite -Name $WebsiteNamed -Timeout '00:00:01' @WithArgs -ErrorAction $ErrorActionPreference
            }
        }
    }
}

Describe 'Stop-CIisWebsite' {
    BeforeEach {
        $Global:Error.Clear()
        $script:websiteName = "Stop-CIisWebsite$($script:testNum)"
        $script:testNum++
        $script:timeoutStart = $false
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:websiteName
        Uninstall-CIisAppPool -Name $script:websiteName
    }

    It 'should stop a started website' {
        GivenWebsite $script:websiteName -IsStarted
        WhenStarting $script:websiteName
        ThenWebsite $script:websiteName -IsStopped
    }

    It 'should do nothing to an already stopped website' {
        GivenWebsite $script:websiteName -IsStopped
        WhenStarting $script:websiteName
        ThenWebsite $script:websiteName -IsStopped
    }

    It 'should stop waiting to stop website' {
        GivenWebsite $script:websiteName -IsStarted
        GivenWebsiteTimesOutStopping
        WhenStarting $script:websiteName -ErrorAction SilentlyContinue
        ThenWebsite $script:websiteName -IsStarted
        ThenError -MatchesRegex 'failed to stop'
    }

    It 'should accept website objects from the pipeline' {
        GivenWebsite $script:websiteName -IsStarted
        Get-CIisWebsite -Name $script:websiteName | WhenStarting
        ThenWebsite $script:websiteName -IsStopped
    }

    It 'should accept website names from the pipeline' {
        GivenWebsite $script:websiteName -IsStarted
        $script:websiteName | WhenStarting
        ThenWebsite $script:websiteName -IsStopped
    }
}
