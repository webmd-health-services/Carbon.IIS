
using module '..\Carbon.IIS\Carbon.IIS.Enums.psm1'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    $script:defaultDefaults = @{}
    (Get-CIisAppPool -Defaults) |
        Select-Object -ExpandProperty 'ProcessModel' |  # ProcessModel doesn't exist on some AppVeyor servers
        Select-Object -ExpandProperty 'Attributes' |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
        'identityType' = [ProcessModelIdentityType]::ApplicationPoolIdentity;
        'idleTimeout' = [TimeSpan]'12:34:00';
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

    $script:excludedAttributes = @()

    $script:initialAttrValues = @{}

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
        ThenHasValues $script:initialAttrValues
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

        $target = $targetParent.ProcessModel
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

Describe 'Set-CIisAppPoolProcessModel' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:appPoolName = "Set-CIisAppPoolProcessModel$($script:testNum)"
        $script:testNum++
        Set-CIisAppPoolProcessModel -AsDefaults @script:defaultDefaults -Reset
        Install-CIisAppPool -Name $script:appPoolName
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName -Reset
        $script:initialAttrValues = @{}
        $appPoolPM = Get-CIIsAppPool -Name $script:appPoolName | Select-Object -ExpandProperty 'ProcessModel'
        foreach ($attr in $appPoolPM.Attributes)
        {
            $script:initialAttrValues[$attr.Name] = $attr.Value
        }
    }

    AfterEach {
        Uninstall-CIisAppPool -Name $script:appPoolName
        Set-CIisAppPoolProcessModel -AsDefaults @script:defaultDefaults -Reset
    }

    It 'should set and reset all values' {
        $infos = @()
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName -Reset
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @script:nonDefaultArgs -Reset -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName -Reset @script:nonDefaultArgs
        ThenHasValues $script:nonDefaultArgs
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName -Reset -WhatIf
        ThenHasValues $script:nonDefaultArgs
    }

    It 'should change values and not reset to defaults' {
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @script:nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $script:nonDefaultArgs

        $someArgs = @{
            'UserName' = 'fubarsnafu';
            'Password' = (ConvertTo-SecureString -String 'ufansrabuf' -AsPlainText -Force);
        }
        Set-CIisAppPoolProcessModel -AppPoolName $script:appPoolName @someArgs
        $someArgs['Password'] = 'ufansrabuf'
        ThenHasValues $someArgs -OrValues $script:nonDefaultArgs
    }

    It 'should change default settings' {
        Set-CIisAppPoolProcessModel -AsDefaults @script:nonDefaultArgs -Reset
        ThenDefaultsSetTo $script:nonDefaultArgs

        $someArgs = @{
            'UserName' = 'fubarsnafu';
            'Password' = (ConvertTo-SecureString -String 'ufansrabuf' -AsPlainText -Force);
        }
        Set-CIisAppPoolProcessModel -AsDefaults @someArgs
        $someArgs['Password'] = 'ufansrabuf'
        ThenDefaultsSetTo $someArgs -OrValues $script:nonDefaultArgs
    }
}
