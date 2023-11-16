BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonSetIisCollection'
    $script:sitePort = 47938
    $script:testDir = $null

    function WhenSetting
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [Object[]] $Item
        )

        $Item | Set-CIisCollection -LocationPath $script:locationPath `
                                   -SectionPath 'system.webServer/httpProtocol' `
                                   -Name 'customHeaders'
    }

    function ThenCollectionIs
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [hashtable[]] $Item
        )

        # Make sure to include the inherited headers in our expectations.
        $Item = & {
            $Item |
                ForEach-Object {
                    if (-not $_.ContainsKey('value'))
                    {
                        $_['value'] = ''
                    }
                    $_ | Write-Output
                } |
                Write-Output
        }

        $localCollection = Get-CIisCollectionItem -LocationPath $script:locationPath `
                                                  -SectionPath 'system.webServer/httpProtocol' `
                                                  -CollectionName 'customHeaders'
        $localCollection | Should -HaveCount $Item.Count

        for ($idx = 0 ; $idx -lt $Item.Count ; ++$idx)
        {
            $actualItem = $localCollection | Select-Object -Index $idx
            $expectedItem = $Item[$idx]

            $actualItem.Attributes.Count | Should -Be $expectedItem.Count

            foreach ($attrName in $expectedItem.Keys)
            {
                $actualItem.GetAttributeValue($attrName) | Should -Be $expectedItem[$attrName]
            }
        }
    }
}

Describe 'Set-CIisCollection' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:locationPath -Path $script:testDir -Binding "http/*:$($script:sitePort):*"
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:locationPath
    }

    It 'should add items with provided names' {
        $names = 'first', 'second', 'third', 'fourth'
        WhenSetting $names
        ThenCollectionIs @(@{ name = 'first' }, @{ name = 'second' }, @{ name = 'third' }, @{ name = 'fourth' })
    }

    It 'should add items with provided attributes' {
        $inputs = @{
            "name" = "first"
            "value" = "firstVal"
        },
        @{
            "name" = "second"
            "value" = "secondVal"
        },
        @{
            "name" = "third"
            "value" = "thirdVal"
        }
        WhenSetting $inputs
        ThenCollectionIs $inputs
    }

    It 'should add both hashtable and string values' {
        $initialItems = 'foo', @{ 'name' = 'bar' }
        WhenSetting $initialItems
        ThenCollectionIs @(@{ name = 'foo' }, @{ name = 'bar' })
    }

    It 'should clear if items exist' {
        $initialName = 'sample item'
        WhenSetting $initialName
        ThenCollectionIs @{ name = $initialName }

        $addedNames = 'first', 'second'
        WhenSetting $addedNames
        ThenCollectionIs @{ name = 'first' },@{ name = 'second' }
    }

    It 'should add items back if they exist and are being set' {
        $initialNames = 'foo', 'bar'
        WhenSetting $initialNames
        ThenCollectionIs @{ name = 'foo' }, @{ name = 'bar' }
        $newNames = 'foo', 'baz'
        WhenSetting $newNames
        ThenCollectionIs @{ name = 'foo' }, @{ name = 'baz' }
    }

    It 'validates unique key attribute exists' {
        Mock -CommandName 'Get-CIisCollectionKeyName' -ModuleName 'Carbon.IIS'
        {
            'hello-world' | Set-CIisCollection -LocationPath $script:locationPath `
                                               -SectionPath 'system.webServer/httpProtocol' `
                                               -Name 'customHeaders' `
                                               -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage '*does not have a unique key attribute*'
    }

    It 'customizes unique key attribute name' {
        {
                @{ statusCode = 401 ; prefixLanguageFilePath = '%SystemDrive%\inetpub\custerr' ; path = '401.htm' } |
                    Set-CIisCollection -LocationPath $script:locationPath `
                                       -SectionPath 'system.webServer/httpErrors' `
                                       -UniqueKeyAttributeName 'statusCode' `
                                       -ErrorAction Stop
            } | Should -Not -Throw
    }

    It 'sets the collection using a configuration element' {
        Suspend-CIisAutoCommit
        $name = "Set-CIisCollection-$([IO.Path]::GetRandomFileName())"
        try
        {
            $appPool = Install-CIisAppPool -Name $name -PassThru
            $schedule = $appPool.Recycling.PeriodicRestart.Schedule
            $times = ((New-TimeSpan -Hours 1), (New-TimeSpan -Hours 2), (New-TimeSpan -Hours 3))
            $times | Set-CIisCollection -ConfigurationElement $schedule
            $schedule | Should -HaveCount 3
            $schedule[0].Time | Should -Be $times[0]
            $schedule[1].Time | Should -Be $times[1]
            $schedule[2].Time | Should -Be $times[2]

            $times = ((New-TimeSpan -Hours 4), (New-TimeSpan -Hours 5))
            $times | Set-CIisCollection -ConfigurationElement $schedule
            $schedule | Should -HaveCount 2
            $schedule[0].Time | Should -Be $times[0]
            $schedule[1].Time | Should -Be $times[1]
        }
        finally
        {
            Resume-CIisAutoCommit -Save
            Uninstall-CIisAppPool -Name $name
        }
    }

    It 'does not disable inheritance' {
        Add-CIisHttpHeader -Name 'Set-CIisCollection' -Value 'Set-CIisCollectionValue'

        WhenSetting @{ name = 'Set-CIisCollection2' ; value = 'Set-CiisCollection2Value' }
        ThenCollectionIs @{ name = 'Set-CIisCollection2' ; value = 'Set-CIisCollection2Value' }
    }
}