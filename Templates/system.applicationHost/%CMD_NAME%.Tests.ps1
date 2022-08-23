using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    #
    $script:defaultDefaults = @{}
    (%CMD_NAME% -AsDefaults).%PROPERTY_NAME%.Attributes |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
        %NON_DEFAULT_ARGS%
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
                Should -Be $expectedValue -Because "should set$($asDefaultsMsg) $($attr.Name) to $($becauseMsg) value"
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
        $script:%TARGET_VAR_NAME% = "%CMD_NAME%$($script:testNum++)"
        %CMD_NAME% -AsDefaults @script:defaultDefaults
        %BEFORE_EACH%
    }

    AfterEach {
        %AFTER_EACH%
        %CMD_NAME% -AsDefaults @script:defaultDefaults
    }

    It 'should set and reset all values' {
        $infos = @()
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME%
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @nonDefaultArgs -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @nonDefaultArgs
        ThenHasValues $nonDefaultArgs
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% -WhatIf
        ThenHasValues $nonDefaultArgs
    }

    It 'should change values and reset to defaults' {
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $nonDefaultArgs

        $someArgs = @{
            PARAM_ONE = VALUE_ONE;
            PARAM_TWO = VALUE_TWO;
        }
        %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% $script:%TARGET_VAR_NAME% @someArgs
        ThenHasValues $someArgs
    }

    It 'should change default settings' {
        %CMD_NAME% -AsDefaults @nonDefaultArgs
        ThenDefaultsSetTo @nonDefaultArgs
    }
}
