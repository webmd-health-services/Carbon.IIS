using module '..\Carbon.Iis'
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

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

    function ThenHasDefaultValues
    {
        ThenHasValues @{}
    }

    function ThenHasValues
    {
        param(
            [hashtable] $Values = @{}
        )

        $website = Get-CIisWebsite -Name $script:websiteName
        $website | Should -Not -BeNullOrEmpty

        $logFile = $website.LogFile
        $logFile | Should -Not -BeNullOrEmpty

        foreach( $attr in $logFile.Schema.AttributeSchemas )
        {
            $currentValue = $logFile.GetAttributeValue($attr.Name)
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
                $expectedValue = [TimeSpan]::New($attr.DefaultValue)
            }

            $currentValue | Should -Be $expectedValue -Because "should set $($attr.Name) to $($becauseMsg) value"
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
        $script:websiteName = "Set-CIisWebsiteLogFile$($script:testNum++)"
        $webroot = New-TestDirectory
        Install-CIisWebsite -Name $script:websiteName -PhysicalPath $webroot -AppPoolName $script:websiteName
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:websiteName
    }

    It 'should set and reset all log file values' {
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @nonDefaultArgs
        ThenHasValues $nonDefaultArgs

        Set-CIisWebsiteLogFile -SiteName $script:websiteName
        ThenHasDefaultValues
    }

    It 'should support WhatIf when updating all values' {
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @nonDefaultArgs -WhatIf
        ThenHasDefaultValues
    }

    It 'should support WhatIf when resetting all values back to defaults' {
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @nonDefaultArgs
        ThenHasValues $nonDefaultArgs
        Set-CIisWebsiteLogFile -SiteName $script:websiteName -WhatIf
        ThenHasValues $nonDefaultArgs
    }

    It 'should change values and reset to defaults' {
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @nonDefaultArgs -ErrorAction Ignore
        ThenHasValues $nonDefaultArgs

        $someArgs = @{
            Directory = "C:\logs";
            Period = [LoggingRolloverPeriod]::Weekly;
        }
        Set-CIisWebsiteLogFile -SiteName $script:websiteName @someArgs
        ThenHasValues $someArgs
    }
}
