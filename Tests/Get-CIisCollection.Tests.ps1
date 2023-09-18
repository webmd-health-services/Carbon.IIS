
using namespace Microsoft.Web.Administration
using namespace System.Runtime.Serialization

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

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

    It 'should error if not a collection' {
        { Get-CIisCollection -LocationPath $script:locationPath `
                             -SectionPath 'system.webServer/httpProtocol' `
                             -ErrorAction 'Stop'
        } | Should -Throw -ExpectedMessage '*is not a collection*'
    }

    It 'gets collection from configuration element' {
        $ce = Get-CIisConfigurationSection -SectionPath 'system.webServer/httpProtocol'
        $ce | Should -Not -BeNullOrEmpty
        $c = Get-CIisCollection -ConfigurationElement $ce -Name 'customHeaders'
        ,$c | Should -Not -BeNullOrEmpty
        ,$c | Should -BeOfType [Microsoft.Web.Administration.ConfigurationElementCollection]
    }

    It 'gets collection from configuration element collection' {
        $site = Get-CIisWebsite -Name $script:locationPath
        $c = Get-CIisCollection -ConfigurationElement $site.LogFile.CustomLogFields
        $null -eq $c | Should -BeFalse
        ,$c | Should -BeOfType [Microsoft.Web.Administration.CustomLogFieldCollection]
    }
}
