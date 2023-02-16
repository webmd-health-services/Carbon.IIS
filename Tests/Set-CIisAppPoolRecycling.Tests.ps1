using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    $script:defaultDefaults = @{}

    # All non-default values.
    $script:nonDefaultArgs = @{
        'disallowOverlappingRotation' = $true;
        'disallowRotationOnConfigChange' = $true;
        'logEventOnRecycle' = [RecyclingLogEventOnRecycle]::None;
    }

    # Values that once set, can only be changed, never removed.
    $script:requiredDefaults = @{
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
        $targetParent | Should -Not -BeNullOrEmpty

        $target = $targetParent.recycling
        $target | Should -Not -BeNullOrEmpty

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
}

Describe 'Set-CIisAppPoolRecycling' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:appPoolName = "Set-CIisAppPoolRecycling$($script:testNum)"
        $script:testNum++
        Set-CIisAppPoolRecycling -AsDefaults @script:defaultDefaults -Reset
        Install-CIisAppPool -Name $script:appPoolName
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Set-CIisAppPoolRecycling -AsDefaults @script:defaultDefaults -Reset
    }

    It 'should set and reset all values' {
        $infos = @()
        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName `
                                 @script:nonDefaultArgs `
                                 -Reset `
                                 -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName `
                                 @script:nonDefaultArgs `
                                 -Reset `
                                 -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName -Reset
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName @script:nonDefaultArgs -Reset -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName -Reset @script:nonDefaultArgs
        ThenHasValues $script:nonDefaultArgs
        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName -Reset -WhatIf
        ThenHasValues $script:nonDefaultArgs
    }

    It 'should change values and not reset to defaults' {
        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName @script:nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $script:nonDefaultArgs

        $someArgs = @{
            DisallowOverlappingRotation = $true;
        }
        Set-CIisAppPoolRecycling -AppPoolName $script:appPoolName @someArgs
        ThenHasValues $someArgs -OrValues $script:nonDefaultArgs
    }

    It 'should change default settings' {
        Set-CIisAppPoolRecycling -AsDefaults @script:nonDefaultArgs -Reset
        ThenDefaultsSetTo $script:nonDefaultArgs

        $someArgs = @{
            LogEventOnRecycle = [RecyclingLogEventOnRecycle]::Requests;
        }
        Set-CIisAppPoolRecycling -AsDefaults @someArgs
        ThenDefaultsSetTo $someArgs -OrValues $script:nonDefaultArgs
    }
}
