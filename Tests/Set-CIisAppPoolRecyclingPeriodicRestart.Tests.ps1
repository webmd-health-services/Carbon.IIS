using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    # All non-default values.
    $script:nonDefaultArgs = @{
        'memory' = 1000000;
        'privateMemory' = 2000000;
        'requests' = 3000000;
        'time' = [TimeSpan]'23:00:00';
    }

    # Sometimes the default values in the schema aren't quite the default values.
    $script:notQuiteDefaultValues = @{
    }

    function ThenHasDefaultValues
    {
        ThenHasValues @{}
    }

    function ThenHasValues
    {
        param(
            [hashtable] $Values = @{},

            [TimeSpan[]] $AndSchedule = @()
        )

        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool  | Should -Not -BeNullOrEmpty

        $target = $appPool.Recycling.PeriodicRestart
        $target | Should -Not -BeNullOrEmpty

        $schedule = $target.Schedule
        $schedule | Should -HaveCount $AndSchedule.Count
        ($schedule | Select-Object -ExpandProperty 'Time' | Sort-Object) -join ', ' | Should -Be (($AndSchedule | Sort-Object) -join ', ')

        foreach( $attr in $target.Schema.AttributeSchemas )
        {
            $currentValue = $target.GetAttributeValue($attr.Name)
            $expectedValue = $attr.DefaultValue
            $becauseMsg = 'default'
            if( $script:notQuiteDefaultValues.ContainsKey($attr.Name))
            {
                $expectedValue = $script:notQuiteDefaultValues[$attr.Name]
            }

            if( $Values.ContainsKey($attr.Name) )
            {
                $expectedValue = $Values[$attr.Name]
                $becauseMsg = 'custom'
            }

            if( $currentValue -is [TimeSpan] )
            {
                if( $expectedValue -match '^\d+$' )
                {
                    $expectedValue = [TimeSpan]::New([long]$expectedValue)
                }
                else
                {
                    $expectedValue = [TimeSpan]$expectedValue
                }
            }

            $currentValue | Should -Be $expectedValue -Because "should set $($attr.Name) to $($becauseMsg) value"
        }
    }
}

Describe 'Set-CIisAppPoolRecyclingPeriodicRestart' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:appPoolName = "Set-CIisAppPoolRecyclingPeriodicRestart$($script:testNum++)"
        Install-CIisAppPool -Name $script:appPoolName
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should set and reset all log file values' {
        $infos = @()
        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName `
                                                @nonDefaultArgs `
                                                -Schedule '01:00:00', '13:00:00' `
                                                -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs -AndSchedule '01:00:00', '13:00:00'

        # Make sure no information messages get written because no changes are being made.
        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName `
                                                @nonDefaultArgs `
                                                -Schedule '01:00:00', '13:00:00' `
                                                -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs -AndSchedule '01:00:00', '13:00:00'

        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName `
                                                @nonDefaultArgs `
                                                -Schedule '12:34:00', '23:45:00' `
                                                -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName @nonDefaultArgs
        ThenHasValues $nonDefaultArgs
        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName -WhatIf
        ThenHasValues $nonDefaultArgs
    }

    It 'should change values and reset to defaults' {
        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName @nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $nonDefaultArgs

        $someArgs = @{
            'memory' = 6000000;
            'privateMemory' = 7000000;
        }
        Set-CIisAppPoolRecyclingPeriodicRestart -AppPoolName $script:appPoolName @someArgs
        ThenHasValues $someArgs
    }

}
