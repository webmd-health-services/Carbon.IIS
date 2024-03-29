
using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    $script:defaultDefaults = @{}
    (Get-CIisWebsite -Defaults).Attributes |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
        'id' = 53;
        'serverAutoStart' = $false;
    }

    # Once you set a website's ID, you can't ever reset it, only change it to a new value.
    $script:requiredDefaults = @{
        'id' = 53;
    }

    # Sometimes the default values in the schema aren't quite the default values.
    $script:notQuiteDefaultValues = @{
        'id' = 53;
    }

    $script:excludedAttributes = @('name', 'state')

    function ThenDefaultsSetTo
    {
        param(
            $Values = @{},

            $OrValues = @{}
        )

        ThenHasValues $Values -OrValues $OrValues -OnDefaults
        $Values['id'] = (Get-CIisWebsite -Name $script:siteName).ID
        $OrValues.Remove('id')
        ThenHasValues $Values -OrValues $OrValues
    }

    function ThenHasDefaultValues
    {
        param(
            [hashtable] $Values = @{}
        )

        ThenHasValues $Values
    }

    function ThenHasValues
    {
        param(
            [Parameter(Position=0)]
            [hashtable] $Values = @{},

            [hashtable] $OrValues = @{},

            [switch] $OnDefaults
        )

        $targetParent = Get-CIisWebsite -Name $script:siteName -Defaults:$OnDefaults
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

Describe 'Set-CIisWebsite' {
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name 'Set-CIisWebsite'
    }

    AfterAll {
        Uninstall-CIisAppPool -Name 'Set-CIisWebsite'
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:siteName = "Set-CIisWebsite$($script:testNum)"
        $script:testNum++
        Set-CIisWebsite -AsDefaults @script:defaultDefaults -Reset
        Install-CIisWebsite -Name $script:siteName -PhysicalPath (New-TestDirectory) -AppPoolName 'Set-CIisWebsite'
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
        Set-CIisWebsite -AsDefaults @script:defaultDefaults -Reset
    }

    It 'should set and reset all values' {
        $infos = @()
        Set-CIisWebsite -Name $script:siteName @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        Set-CIisWebsite -Name $script:siteName @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        Set-CIisWebsite -Name $script:siteName @script:requiredDefaults -Reset
        ThenHasDefaultValues @{ 'id' = $script:nonDefaultArgs['id'] }
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisWebsite -Name $script:siteName @script:nonDefaultArgs -Reset -WhatIf
        ThenHasDefaultValues @{ 'id' = (Get-CIisWebsite -Name $script:siteName).Id }
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisWebsite -Name $script:siteName -Reset @script:nonDefaultArgs
        ThenHasValues $script:nonDefaultArgs
        Set-CIisWebsite -Name $script:siteName -Reset -WhatIf
        ThenHasValues $script:nonDefaultArgs
    }

    It 'should change default settings' {
        Set-CIisWebsite -AsDefaults -Reset
        ThenDefaultsSetTo @{ 'id' = 0 ; 'serverAutoStart' = $true }

        Set-CIisWebsite -AsDefaults -ServerAutoStart $false
        ThenDefaultsSetTo @{ 'id' = 0 ; 'serverAutoStart' = $false }
    }
}
