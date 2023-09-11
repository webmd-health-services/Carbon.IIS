BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonRemoveIisCollectionItem'
    $script:sitePort = 47038
    $script:testDir = $null


    function HasItemWithValue
    {
        [CmdletBinding()]
        param(
            [string] $Value,
            [switch] $Not
        )

        $collection = Get-CIisCollection -LocationPath $script:locationPath `
                                         -SectionPath 'system.webServer/httpProtocol' `
                                         -Name 'customHeaders'
        $headerExists = $collection | Where-Object { $_.GetAttributeValue('name') -eq $Value }

        if ($not)
        {
            $headerExists | Should -BeNullOrEmpty
        }
        else
        {
            $headerExists | Should -Not -BeNullOrEmpty
        }
    }

    function GivenItemAdded {
        [CmdletBinding()]
        param(
            [string] $Value
        )

        $Value | Set-CIisCollectionItem -LocationPath $script:locationPath `
                                        -SectionPath 'system.webServer/httpProtocol' `
                                        -CollectionName 'customHeaders'
    }

    function GivenRemoves {
        [CmdletBinding()]
        param(
            [string] $Value
        )

        Remove-CIisCollectionItem -LocationPath $script:locationPath `
                                  -SectionPath 'system.webServer/httpProtocol' `
                                  -CollectionName 'customHeaders' `
                                  -Value $Value
    }
}

Describe 'Remove-CIisCollectionItem' {
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

    It 'should warn item doesn''t exist' {
        $value = 'X-RemoveItem'
        GivenItemAdded 'random-item'
        HasItemWithValue -Value $value -Not
        {
            Remove-CIisCollectionItem -LocationPath $script:locationPath `
                                   -SectionPath 'system.webServer/httpProtocol' `
                                   -CollectionName 'customHeaders' `
                                   -Value $Value `
                                   -ErrorAction 'Stop'
        } | Should -Throw -ExpectedMessage '*Unable to find item*'

        HasItemWithValue -Value $value -Not
    }

    It 'should remove item with provided value' {
        $value = 'X-RemoveItem'
        GivenItemAdded $value
        HasItemWithValue -Value $value
        GivenRemoves $value
        HasItemWithValue -Value $value -Not
    }

    It 'should error if collection key not found' {
        Mock -CommandName 'Get-CIisCollectionKeyName' -ModuleName 'Carbon.IIS'
        {
            Remove-CIisCollectionItem -LocationPath $script:locationPath `
                                      -SectionPath 'system.webServer/httpProtocol' `
                                      -CollectionName 'customHeaders' `
                                      -Value 'no-key' `
                                      -ErrorAction 'Stop'
        } | Should -Throw -ExpectedMessage '*Unable to find key*'
    }
}