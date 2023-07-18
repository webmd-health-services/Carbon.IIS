BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonSetIisCollection'
    $script:sitePort = 47938
    $script:testDir = $null

    function GivenItemsAreAdded
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [object[]] $ItemsToAdd
        )

        $ItemsToAdd | Set-CIisCollection -LocationPath $script:locationPath `
                                         -SectionPath 'system.webServer/httpProtocol' `
                                         -Name 'customHeaders'
    }

    function ThenError
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [object[]] $ItemsToAdd,
            [string] $ErrorMessage
        )

        {
            $ItemsToAdd | Set-CIisCollection -LocationPath $script:locationPath `
                                             -SectionPath 'system.webServer/httpProtocol' `
                                             -Name 'customHeaders' `
                                             -ErrorAction 'Stop'
        } | Should -Throw -ExpectedMessage $ErrorMessage
    }

    function ThenItemsValid
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [Object[]] $addedItems
        )

        $localCollection = Get-CIisCollection -LocationPath $script:locationPath `
                                              -SectionPath 'system.webServer/httpProtocol' `
                                              -Name 'customHeaders'
        $localCollection | Should -HaveCount $addedItems.Count

        foreach ($item in $addedItems)
        {
            $inCollection = $false

            foreach ($collectionItem in $localCollection)
            {
                if ($item -is [string] -and $collectionItem['name'] -eq $item)
                {
                    $inCollection = $true
                    break
                }
                elseif ($item -is [hashtable])
                {
                    $allValid = $true
                    foreach ($key in $item.Keys)
                    {
                        if ($item[$key] -ne $collectionItem.GetAttributeValue($key))
                        {
                            $allValid = $false
                        }
                    }
                    if ($allValid)
                    {
                        $inCollection = $true
                        break
                    }
                }
            }
            $inCollection | Should -BeTrue
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
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:locationPath -Path $script:testDir -Binding "http/*:$($script:sitePort):*"
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:locationPath
    }

    It 'should add items with provided names' {
        $names = 'first', 'second', 'third', 'fourth'
        GivenItemsAreAdded $names
        ThenItemsValid $names
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
        GivenItemsAreAdded $inputs
        ThenItemsValid $inputs
    }

    It 'should add both hashtable and string values' {
        $initialItems = 'foo', @{ 'name' = 'bar' }
        GivenItemsAreAdded $initialItems
        ThenItemsValid $initialItems
    }

    It 'should clear if items exist' {
        $initialName = 'sample item'
        GivenItemsAreAdded $initialName
        ThenItemsValid $initialName

        $addedNames = 'first', 'second'
        GivenItemsAreAdded $addedNames
        ThenItemsValid $addedNames
    }

    It 'should add items back if they exist and are being set' {
        $initialNames = 'foo', 'bar'
        GivenItemsAreAdded $initialNames
        ThenItemsValid $initialNames
        $newNames = 'foo', 'baz'
        GivenItemsAreAdded $newNames
        ThenItemsValid $newNames
    }

    It 'should error if key not found' {
        Mock -CommandName 'Get-CIisCollectionKeyName' -ModuleName 'Carbon.IIS'
        ThenError -ItemsToAdd 'hello-world' -ErrorMessage 'Unable to find key*'
    }
}