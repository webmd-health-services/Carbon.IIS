BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonGetIisCollection'
    $script:sitePort = 47938
    $script:testDir = $null

    function GetNewCollection {
        [CmdletBinding()]
        param()
        return Get-CIisCollection -LocationPath $script:locationPath `
                                  -SectionPath 'system.webServer/httpProtocol' `
                                  -Name 'customHeaders'
    }

    function GetGlobalCollection {
        [CmdletBinding()]
        param()
        return Get-CIisCollection -SectionPath 'system.webServer/httpProtocol' `
                                  -Name 'customHeaders'

    }
}

Describe 'Get-CIisCollection' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:locationPath -Path $script:testDir -Binding "http/*:$($script:sitePort):*"
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:locationPath
    }

    It 'should get the collection for the locationPath' {
        $collection = GetNewCollection
        $collection | Should -HaveCount (GetGlobalCollection).Count
    }

    It 'should have newly added items' {
        $collection = GetNewCollection
        $newItem = $collection.CreateElement('add')
        $newItem.SetAttributeValue('name', 'foobarbaz')
        $collection.Add($newItem)
        Save-CIisConfiguration

        $collection = GetNewCollection
        $globalCollection = GetGlobalCollection
        $expectedCount = $globalCollection.Count + 1
        $collection | Should -HaveCount $expectedCount

        $hasName = $false
        foreach ($item in $collection)
        {
            if ($item['name'] -eq 'foobarbaz')
            {
                $hasName = $true
                break
            }
        }
        $hasName | Should -BeTrue
    }
}