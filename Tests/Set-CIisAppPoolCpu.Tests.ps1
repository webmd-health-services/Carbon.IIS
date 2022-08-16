using module '..\Carbon.Iis'

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    function ThenHasDefaultValues
    {
        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool | Should -Not -BeNullOrEmpty
        $cpu = $appPool.Cpu
        $cpu | Should -Not -BeNullOrEmpty

        foreach( $attr in $cpu.Schema.AttributeSchemas )
        {
            $currentValue = $cpu.GetAttributeValue($attr.Name)
            $defaultValue = $attr.DefaultValue
            if( $currentValue -is [TimeSpan] )
            {
                $defaultValue = [TimeSpan]::New($attr.DefaultValue)
            }
            $currentValue | Should -Be $defaultValue -Because "should reset $($attr.Name) to default value"
        }
    }

    function ThenHasValues
    {
        param(
            [hashtable] $Values
        )

        $appPool = Get-CIisAppPool -Name $script:appPoolName
        $appPool | Should -Not -BeNullOrEmpty
        $cpu = $appPool.Cpu
        $cpu | Should -Not -BeNullOrEmpty
        $cpu.Action | Should -Be $Values['Action']
        $cpu.Limit | Should -Be $Values['Limit']
        # Need hardware where these CPU settings exist.
        # $cpu.NumaNodeAffinityMode | Should -Be $Values['NumaNodeAffinityMode']
        # $cpu.NumaNodeAssigment | Should -Be $Values['NumaNodeAssigment']
        # $cpu.ProcessorGroup | Should -Be $Values['ProcessorGroup']
        $cpu.ResetInterval | Should -Be $Values['ResetInterval']
        $cpu.SmpAffinitized | Should -Be $Values['SmpAffinitized']
        $cpu.SmpProcessorAffinityMask | Should -Be $Values['SmpProcessorAffinityMask']
        $cpu.SmpProcessorAffinityMask2 | Should -Be $Values['SmpProcessorAffinityMask2']
    }
}

Describe 'Set-CIisAppPoolCpu' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:appPoolName = "Set-CIisAppPoolCpu$($script:testNum++)"
        Install-CIisAppPool -Name $script:appPoolName
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
    }

    It 'should set and reset all CPU values' {
        $setArgs = @{
            Action = 'Throttle';
            Limit = (1000 * 50);
            NumaNodeAffinityMode = 'Hard';
            NumaNodeAssignment = 'WindowsScheduling';
            ProcessorGroup = 1;
            ResetInterval = '00:10:00';
            SmpAffinitized = $true;
            SmpProcessorAffinityMask = 0x1;
            SmpProcessorAffinityMask2 = 0x2;
        }
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @setArgs
        ThenHasValues $setArgs

        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        $setArgs = @{
            Action = 'Throttle';
            Limit = (1000 * 50);
            NumaNodeAffinityMode = 'Hard';
            NumaNodeAssignment = 'WindowsScheduling';
            ProcessorGroup = 1;
            ResetInterval = '00:10:00';
            SmpAffinitized = $true;
            SmpProcessorAffinityMask = 0x1;
            SmpProcessorAffinityMask2 = 0x2;
        }
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @setArgs -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        $setArgs = @{
            Action = 'Throttle';
            Limit = (1000 * 50);
            NumaNodeAffinityMode = 'Hard';
            NumaNodeAssignment = 'WindowsScheduling';
            ProcessorGroup = 1;
            ResetInterval = '00:10:00';
            SmpAffinitized = $true;
            SmpProcessorAffinityMask = 0x1;
            SmpProcessorAffinityMask2 = 0x2;
        }
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @setArgs
        ThenHasValues $setArgs
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName -WhatIf
        ThenHasValues $setArgs
    }

    It 'should change values and reset to defaults' {
        $setArgs = @{
            Action = 'Throttle';
            Limit = (1000 * 50);
            NumaNodeAffinityMode = 'Hard';
            NumaNodeAssignment = 'WindowsScheduling';
            ProcessorGroup = 1;
            ResetInterval = '00:10:00';
            SmpAffinitized = $true;
            SmpProcessorAffinityMask = 0x1;
            SmpProcessorAffinityMask2 = 0x2;
        }
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @setArgs
        ThenHasValues $setArgs
        $setArgs.Remove('ProcessorGroup')
        $setArgs.Remove('NumaNodeAffinityMode')
        $setArgs.Remove('NumaNodeAssignment')
        $setArgs['Action'] = 'KillW3wp'
        $setArgs['Limit'] = 10000
        $setArgs['ResetInterval'] = '01:00:00'
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @setArgs
        ThenHasValues $setArgs
    }
}
