using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    $script:defaultDefaults = @{}
    (%GET_CMD_NAME% -Defaults).%PROPERTY_NAME%.Attributes |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
        %NON_DEFAULT_ARGS%
    }

    # Values that once set, can only be changed, never removed.
    $script:requiredDefaults = @{
        'id' = 53;
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

        $targetParent = %GET_CMD_NAME% -Name $script:%TARGET_VAR_NAME% -Defaults:$OnDefaults
        $targetParent | Should -Not -BeNullOrEmpty

        $target = $targetParent.%PROPERTY_NAME%
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

Describe '%CMD_NAME%' {
    BeforeAll {
        Start-W3ServiceTestFixture
        %BEFORE_ALL%
    }

    AfterAll {
        %AFTER_ALL%
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:%TARGET_VAR_NAME% = "%CMD_NAME%$($script:testNum)"
        $script:testNum++
        %CMD_NAME% -AsDefaults @script:defaultDefaults -Reset
        %BEFORE_EACH%
    }

    AfterEach {
        %AFTER_EACH%
        %CMD_NAME% -AsDefaults @script:defaultDefaults -Reset
    }

    It 'should set and reset all values' {
        $infos = @()
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% -Reset
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @script:nonDefaultArgs -Reset -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% -Reset @script:nonDefaultArgs
        ThenHasValues $script:nonDefaultArgs
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% -Reset -WhatIf
        ThenHasValues $script:nonDefaultArgs
    }

    It 'should change values and not reset to defaults' {
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @script:nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $script:nonDefaultArgs

        $someArgs = @{
            PARAM_ONE = VALUE_ONE;
            PARAM_TWO = VALUE_TWO;
        }
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @someArgs
        ThenHasValues $someArgs -OrValues $script:nonDefaultArgs
    }

    It 'should change default settings' {
        %CMD_NAME% -AsDefaults @script:nonDefaultArgs -Reset
        ThenDefaultsSetTo $script:nonDefaultArgs

        $someArgs = @{
            PARAM_ONE = VALUE_ONE;
            PARAM_TWO = VALUE_TWO;
        }
        $CMD_NAME% -AsDefaults @someArgs
        ThenDefaultsSetTo $someArgs -OrValues $script:nonDefaultArgs
    }
}
