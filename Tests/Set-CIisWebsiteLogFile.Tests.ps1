using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    $script:defaultDefaults = @{}
    (Get-CIisWebsite -Defaults).LogFile.Attributes |
        Where-Object 'IsInheritedFromDefaultValue' -EQ $false |
        ForEach-Object { $script:defaultDefaults[$_.Name] = $_.Value }

    # All non-default values.
    $script:nonDefaultArgs = @{
        CustomLogPluginClsid = '931a0831-2301-4a0b-9887-ee9a7d0c10df';
        Directory = 'C:\my\log\files';
        Enabled = $false;
        FlushByEntryCountW3CLog = 1000;
        LocalTimeRollover = $true;
        LogExtFileFlags = ([LogExtFileFlags]::Date -bor [LogExtFileFlags]::Host);
        LogFormat = [LogFormat]::Custom;
        LogSiteID = $true;
        LogTargetW3C = ([LogTargetW3C]::File -bor [LogTargetW3C]::ETW);
        MaxLogLineLength = 2000;
        Period = [LoggingRolloverPeriod]::Hourly;
        TruncateSize = 1048576;
    }

    # Sometimes the default values in the schema aren't quite the default values.
    $script:notQuiteDefaultValues = @{
        Directory = '%SystemDrive%\inetpub\logs\LogFiles';
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

        $targetParent = Get-CIisWebsite -Name $script:websiteName
        $targetParent | Should -Not -BeNullOrEmpty

        $target = $targetParent.LogFile
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

Describe 'Set-CIisWebsiteLogFile' {
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name 'Set-CIisWebsiteLogFile'
    }

    AfterAll {
        Uninstall-CIisAppPool -Name 'Set-CIisWebsiteLogFile'
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:websiteName = "Set-CIisWebsiteLogFile$($script:testNum)"
        $script:testNum++
        Set-CIisWebsiteLogFile -AsDefaults @script:defaultDefaults -Reset
        Install-CIisWebsite -Name $script:websiteName -PhysicalPath (New-TestDirectory) -AppPoolName $script:websiteName
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:websiteName
        Set-CIisWebsiteLogFile -AsDefaults @script:defaultDefaults -Reset
    }

    It 'should set and reset all values' {
        $infos = @()
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -Not -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        # Make sure no information messages get written because no changes are being made.
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @script:nonDefaultArgs -Reset -InformationVariable 'infos'
        $infos | Should -BeNullOrEmpty
        ThenHasValues $script:nonDefaultArgs

        Set-CIisWebsiteLogFile -SiteName $script:websiteName -Reset
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @script:nonDefaultArgs -Reset -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisWebsiteLogFile -SiteName $script:websiteName -Reset @script:nonDefaultArgs
        ThenHasValues $script:nonDefaultArgs
        Set-CIisWebsiteLogFile -SiteName $script:websiteName -Reset -WhatIf
        ThenHasValues $script:nonDefaultArgs
    }

    It 'should change values and not reset to defaults' {
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @script:nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $script:nonDefaultArgs

        $someArgs = @{
            Directory = "C:\logs";
            Period = [LoggingRolloverPeriod]::Weekly;
        }
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @someArgs
        ThenHasValues $someArgs -OrValues $script:nonDefaultArgs
    }

    It 'should change default settings' {
        Set-CIisWebsiteLogFile -AsDefaults @script:nonDefaultArgs -Reset
        ThenDefaultsSetTo $script:nonDefaultArgs

        $someArgs = @{
            Directory = "C:\logs";
            Period = [LoggingRolloverPeriod]::Weekly;
        }
        Set-CIisWebsiteLogFile -AsDefaults @someArgs
        ThenDefaultsSetTo $someArgs -OrValues $script:nonDefaultArgs
    }
}
