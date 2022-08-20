using module '..\Carbon.Iis'

using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    $script:defaultDefaults = @{}
    (Get-CIisAppPool -Defaults).Cpu |
        Where-Object { $_ | Get-Member -Name 'IsInheritedFromDefaultValue' } |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
            Action = [ProcessorAction]::Throttle;
            Limit = (1000 * 50);
            NumaNodeAffinityMode = [CIisNumaNodeAffinityMode]::Hard;
            NumaNodeAssignment = [CIisNumaNodeAssignment]::WindowsScheduling;
            ProcessorGroup = 1;
            ResetInterval = '00:10:00';
            SmpAffinitized = $true;
            SmpProcessorAffinityMask = 0x1;
            SmpProcessorAffinityMask2 = 0x2;
    }

    # Sometimes the default values in the schema aren't quite the default values.
    $script:notQuiteDefaultValues = @{
    }

    function ThenDefaultsSetTo
    {
        ThenHasValues $script:nonDefaultArgs -OnDefaults
        ThenHasValues $script:nonDefaultArgs
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

            [switch] $OnDefaults
        )

        $appPool = Get-CIisAppPool -Name $script:appPoolName -Defaults:$OnDefaults
        $appPool | Should -Not -BeNullOrEmpty

        $target = $appPool.Cpu
        $target | Should -Not -BeNullOrEmpty

        $asDefaultsMsg = ''
        if( $OnDefaults )
        {
            $asDefaultsMsg = ' as default'
        }

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

            $currentValue |
                Should -Be $expectedValue -Because "should set$($asDefaultsMsg) $($attr.Name) to $($becauseMsg) value"
        }
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
        Set-CIisAppPoolCpu -AsDefaults @script:defaultDefaults
        Install-CIisAppPool -Name $script:appPoolName
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Set-CIisAppPoolCpu -AsDefaults @script:defaultDefaults
    }

    It 'should set and reset all  values' {
        $infos = @()
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @nonDefaultArgs -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @nonDefaultArgs
        ThenHasValues $nonDefaultArgs
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName -WhatIf
        ThenHasValues $nonDefaultArgs
    }

    It 'should change values and reset to defaults' {
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $nonDefaultArgs
        $someArgs = @{
            'action' = [ProcessorAction]::KillW3wp;
            'limit' = 10000;
            'resetInterval' = '01:00:00';
        }
        Set-CIisAppPoolCpu -AppPoolName $script:appPoolName @someArgs
        ThenHasValues $someArgs
    }

    It 'should change default settings' {
        Set-CIisAppPoolCpu -AsDefaults @nonDefaultArgs
        ThenDefaultsSetTo @nonDefaultArgs
    }
}
