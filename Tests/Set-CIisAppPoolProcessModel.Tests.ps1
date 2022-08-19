
using module '..\Carbon.IIS\Carbon.IIS.Enums.psm1'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    #
    $script:defaultDefaults = @{}
    (Set-CIisAppPoolProcessModel -AsDefaults).ProcessModel.Attributes |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
        'identityType' = [ProcessModelIdentityType]::ApplicationPoolIdentity;
        'idleTimeout' = [TimeSpan]'00:00:00';
        'idleTimeoutAction' = [IdleTimeoutAction]::Suspend;
        'loadUserProfile' = $true;
        'logEventOnProcessModel' = [ProcessModelLogEventOnProcessModel]::None;
        'logonType' = [CIisProcessModelLogonType]::Service;
        'manualGroupMembership' = $true;
        'maxProcesses' = [UInt32]2;
        'pingingEnabled' = $true;
        'pingInterval' = [TimeSpan]'00:00:10';
        'pingResponseTime' = [TimeSpan]'00:05:00';
        'requestQueueDelegatorIdentity' = 'SYSTEM';
        'setProfileEnvironment' = $false;
        'shutdownTimeLimit' = [TimeSpan]'00:00:30';
        'startupTimeLimit' = [TimeSpan]'00:05:00';
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

        $targetParent = Get-CIisAppPool -Name $script:appPoolName -Defaults:$OnDefaults
        $targetParent | Should -Not -BeNullOrEmpty

        $target = $targetParent.ProcessModel
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

            if( $expectedValue -is [securestring] )
            {
                $expectedValue = [pscredential]::New('ignoded', $expectedValue).GetNetworkCredential().Password
            }

            $currentValue = $target.GetAttributeValue($attr.Name)
            if( $currentValue -is [securestring] )
            {
                $currentValue = [pscredential]::New('ignorded', $currentValue).GetNetworkCredential().Password
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

Describe 'Set-CIisAppPoolProcessModel' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:appPoolName = "Set-CIisAppPoolProcessModel$($script:testNum++)"
        Set-CIisAppPoolProcessModel -AsDefaults @script:defaultDefaults
        Install-CIisAppPool -Name $script:appPoolName
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Set-CIisAppPoolProcessModel -AsDefaults @script:defaultDefaults
    }

    It 'should set and reset all values' {
        $infos = @()
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @nonDefaultArgs -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $nonDefaultArgs

        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @nonDefaultArgs -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @nonDefaultArgs
        ThenHasValues $nonDefaultArgs
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName -WhatIf
        ThenHasValues $nonDefaultArgs
    }

    It 'should change values and reset to defaults' {
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $nonDefaultArgs

        $someArgs = @{
            'UserName' = 'fubarsnafu';
            'Password' = (ConvertTo-SecureString -String 'ufansrabuf' -AsPlainText -Force);
        }
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @someArgs
        ThenHasValues $someArgs
    }

    It 'should change default settings' {
        Set-CIisAppPoolProcessModel -AsDefaults @nonDefaultArgs
        ThenDefaultsSetTo @nonDefaultArgs
    }
}
