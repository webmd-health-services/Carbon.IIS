using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    #
    $script:defaultDefaults = @{}
    (Get-CIisAppPool -Defaults).Attributes |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
        'autoStart' = $false;
        'CLRConfigFile' = 'some config file';
        'enable32BitAppOnWin64' = $true;
        'enableConfigurationOverride' = $false;
        'managedPipelineMode' = [Microsoft.Web.Administration.ManagedPipelineMode]::Classic;
        'managedRuntimeLoader' = 'myloader.dll';
        'managedRuntimeVersion' = 'v4.0';
        'passAnonymousToken' = $false;
        'queueLength' = [UInt32]2000;
        'startMode' = [Microsoft.Web.Administration.StartMode]::AlwaysRunning;
    }

    # Sometimes the default values in the schema aren't quite the default values.
    $script:notQuiteDefaultValues = @{
        'managedRuntimeVersion' = 'v4.0'
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

        $targetParent = Get-CIisAppPool -Name $script:appPoolName -Defaults:$OnDefaults
        $targetParent | Should -Not -BeNullOrEmpty

        $target = $targetParent
        $target | Should -Not -BeNullOrEmpty

        $asDefaultsMsg = ''
        if( $OnDefaults )
        {
            $asDefaultsMsg = ' as default'
        }

        foreach( $attr in $target.Schema.AttributeSchemas )
        {
            if( $attr.Name -in @('applicationPoolSid', 'state', 'name') )
            {
                continue
            }

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

Describe 'Set-CIisAppPool' {
    BeforeAll {
        Start-W3ServiceTestFixture

    }

    AfterAll {

        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:appPoolName = "Set-CIisAppPool$($script:testNum++)"
        Set-CIisAppPool -AsDefaults @script:defaultDefaults
        Install-CIisAppPool -Name $script:appPoolName
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Set-CIisAppPool -AsDefaults @script:defaultDefaults
    }

    It 'should set and reset all values' {
        $infos = @()
        Set-CIisAppPool -AppPoolName $script:appPoolName @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        Set-CIisAppPool -AppPoolName $script:appPoolName @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        Set-CIisAppPool -AppPoolName $script:appPoolName
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisAppPool -AppPoolName $script:appPoolName @nonDefaultArgs -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisAppPool -AppPoolName $script:appPoolName @nonDefaultArgs
        ThenHasValues $nonDefaultArgs
        Set-CIisAppPool -AppPoolName $script:appPoolName -WhatIf
        ThenHasValues $nonDefaultArgs
    }

    It 'should change values and reset to defaults' {
        Set-CIisAppPool -AppPoolName $script:appPoolName @nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $nonDefaultArgs

        $someArgs = @{
            managedRuntimeVersion = 'v2.0';
            queueLength = [UInt32]3000;
        }
        Set-CIisAppPool -AppPoolName $script:appPoolName @someArgs
        ThenHasValues $someArgs
    }

    It 'should change default settings' {
        Set-CIisAppPool -AsDefaults @nonDefaultArgs
        ThenDefaultsSetTo @nonDefaultArgs
    }
}
