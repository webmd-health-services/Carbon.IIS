using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 10

    $script:defaultDefaults = @{}

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

    $script:excludedAttributes = @()

    function ThenDefaultsSetTo
    {
        param(
            [hashtable] $Values = @{},

            [hashtable] $OrValues = @{}
        )

        ThenHasValues $Values -OrValues $OrValues -OnDefaults
        ThenHasValues $Values -OrValues $OrValues
    }

    function ThenHasDefaultValues
    {
        ThenHasValues @{}
    }

    function ThenHasValues
    {
        param(
            [Parameter(Position=0)]
            [hashtable] $Values = @{},

            [TimeSpan[]] $AndSchedule = @(),

            [hashtable] $OrValues = @{},

            [switch] $OnDefaults
        )

        $getArgs = @{}
        if ($OnDefaults)
        {
            $getArgs['Defaults'] = $true
        }
        else
        {
            $getArgs['Name'] = $script:appPoolName
        }
        $targetParent = Get-CIisAppPool @getArgs
        $targetParent  | Should -Not -BeNullOrEmpty

        $target = $targetParent.Recycling.PeriodicRestart
        $target | Should -Not -BeNullOrEmpty

        $schedule = $target.Schedule
        $schedule | Should -HaveCount $AndSchedule.Count
        ($schedule |
            Select-Object -ExpandProperty 'Time' |
            Sort-Object) -join ', ' |
            Should -Be (($AndSchedule | Sort-Object) -join ', ')

        $asDefaultsMsg = ''
        if( $OnDefaults )
        {
            $asDefaultsMsg = ' as default'
        }

        foreach( $attr in $target.Schema.AttributeSchemas )
        {
            if( $attr.Name -in $script:excludedAttributes )
            {
                continue
            }

            $expectedValue = $attr.DefaultValue
            $becauseMsg = 'default'
            $setMsg = 'set'
            if( $script:notQuiteDefaultValues.ContainsKey($attr.Name))
            {
                $expectedValue = $script:notQuiteDefaultValues[$attr.Name]
            }

            if( $Values.ContainsKey($attr.Name) )
            {
                $expectedValue = $Values[$attr.Name]
                $becauseMsg = 'custom'
            }
            elseif( $OrValues.ContainsKey($attr.Name) )
            {
                $expectedValue = $OrValues[$attr.Name]
                $becauseMsg = 'custom'
                $setMsg = 'not set'
            }

            $currentValue = $target.GetAttributeValue($attr.Name)
            if( $currentValue -is [securestring] )
            {
                $currentValue = [pscredential]::New('ignored', $currentValue).GetNetworkCredential().Password
            }
            elseif( $currentValue -is [TimeSpan] )
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

            $currentValue |
                Should -Be $expectedValue -Because "should $($setMsg)$($asDefaultsMsg) $($attr.Name) to $($becauseMsg) value"
        }
    }

    function ThenNoError
    {
        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Set-CIisAppPoolPeriodicRestart' {
    BeforeAll {
        Set-CIisAppPoolPeriodicRestart -AsDefaults @script:defaultDefaults -Reset
        Start-W3ServiceTestFixture
        Write-Debug 'Started test fixture.'
    }

    AfterAll {
        Set-CIisAppPoolPeriodicRestart -AsDefaults @script:defaultDefaults -Reset
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:appPoolName = "$($PSCommandPath | Split-Path -Leaf)-$($script:testNum)"
        $script:testNum++
        Write-Debug 'Reset defalt periodic restart settings'
        Install-CIisAppPool -Name $script:appPoolName
        Write-Debug "Installed $($script:appPoolName) app pool"
        $Global:Error.Clear()
        # Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName -Reset
        # Write-Debug "Reset $($script:appPoolName) app pool"
        # Start-Sleep -Seconds 5
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should set a single schedule' {
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName `
                                       @script:nonDefaultArgs `
                                       -Schedule '21:43:00' `
                                       -Reset
        ThenHasValues $script:nonDefaultArgs -AndSchedule '21:43:00'
        ThenNoError
    }

    It 'should set no schedule' {
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName @script:nonDefaultArgs -Reset
        ThenHasValues $script:nonDefaultArgs -AndSchedule @()
    }

    It 'should set and reset all values' {
        $infos = @()
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName `
                                       @script:nonDefaultArgs `
                                       -Schedule '12:34:00', '23:45:00' `
                                       -Reset `
                                       -InformationVariable 'infos'
        Write-Debug "Setting $($script:appPoolName) app pool"
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs -AndSchedule '12:34:00', '23:45:00'

        # Make sure no information messages get written because no changes are being made.
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName `
                                       @script:nonDefaultArgs `
                                       -Schedule '12:34:00', '23:45:00' `
                                       -Reset `
                                       -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs -AndSchedule '12:34:00', '23:45:00'

        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName -Reset
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName `
                                       @script:nonDefaultArgs `
                                       -Schedule '12:34:00', '23:45:00' `
                                       -Reset `
                                       -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName -Reset @script:nonDefaultArgs
        ThenHasValues $script:nonDefaultArgs
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName -Reset -WhatIf
        ThenHasValues $script:nonDefaultArgs
    }

    It 'should change values and not reset to defaults' {
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName @script:nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $script:nonDefaultArgs

        $someArgs = @{
            'memory' = 6000000;
            'privateMemory' = 7000000;
        }
        Set-CIisAppPoolPeriodicRestart -AppPoolName $script:appPoolName @someArgs
        ThenHasValues $someArgs -OrValues $script:nonDefaultArgs
    }

    It 'should change default settings' {
        Set-CIisAppPoolPeriodicRestart -AsDefaults @script:nonDefaultArgs -Reset
        ThenDefaultsSetTo $script:nonDefaultArgs

        $someArgs = @{
            'memory' = 6000000;
            'privateMemory' = 7000000;
        }
        Set-CIisAppPoolPeriodicRestart -AsDefaults @someArgs
        ThenDefaultsSetTo $someArgs -OrValues $script:nonDefaultArgs
    }
}
