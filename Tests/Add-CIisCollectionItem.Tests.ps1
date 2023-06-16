BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonAddIisCollectionItem'
    $script:sitePort = 47038
    $script:testDir = $null

    function GivenValueAdded {
        [CmdletBinding()]
        param(
            [string] $Value
        )

        Add-CIisCollectionItem -LocationPath $script:locationPath `
                               -SectionPath 'system.webServer/httpProtocol' `
                               -CollectionName 'customHeaders' `
                               -Value $Value
    }

    function GivenAttributesAdded {
        [CmdletBinding()]
        param(
            [hashtable] $Attribute
        )

        Add-CIisCollectionItem -LocationPath $script:locationPath `
                               -SectionPath 'system.webServer/httpProtocol' `
                               -CollectionName 'customHeaders' `
                               -Attribute $Attribute
    }

    function InCollection {
        [CmdletBinding()]
        param(
            [Object] $Item
        )

        $collection = Get-CIisCollection -LocationPath $script:locationPath `
                                         -SectionPath 'system.webServer/httpProtocol' `
                                         -Name 'customHeaders'
        $collectionKey = Get-CIisCollectionKeyName -Collection $collection

        $itemExists = $false
        foreach ($collectionItem in $collection)
        {
            if ($Item -is [string])
            {
                if ($collectionItem.GetAttributeValue($collectionKey) -eq $Item)
                {
                    $itemExists = $true
                    break
                }
            }
            if ($Item -is [hashtable])
            {
                $allFieldsMatch = $true
                foreach ($key in $Item.Keys)
                {
                    if ($collectionItem[$key] -ne $Item[$key])
                    {
                        $allFieldsMatch = $false
                        break
                    }
                }

                if ($allFieldsMatch)
                {
                    $itemExists = $true
                    break
                }
            }
            # if ($Item -is [hashtable])
            # {
            #     $allMatch = $true
            #     foreach ($key in $Item.Keys)
            #     {
            #         if ($collectionItem[$key] -ne $Item[$key])
            #         {
            #             $allMatch = $false
            #             break
            #         }
            #     }

            #     if ($allMatch)
            #     {
            #         $itemExists = $true
            #         break
            #     }
            # }
            # elseif ($item -is [string] -and $collectionItem[$collectionKey] -eq $Item)
            # {
            #     $itemExists = $true
            #     break
            # }
        }
        # $itemExists | Should -BeTrue
        return $itemExists
    }
}


Describe 'Add-CIisCollectionItem' {
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

    It 'should successfully add item if key provided' {
        $value = 'X-AddIisItem'
        GivenValueAdded $value
        InCollection $value | Should -BeTrue
    }

    It 'should successfully add item if hashtable provided with key' {
        $attributes = @{ 'name' = 'X-AddIisItem'; 'value' = 'dont add' }
        GivenAttributesAdded $attributes
        InCollection $attributes | Should -BeTrue
    }

    It 'should not add item if item with same key exists' {
        $value = 'X-AddIisItem'
        GivenValueAdded $value
        InCollection $value | Should -BeTrue

        $newValue = @{ 'name' = 'X-AddIisItem'; 'value' = 'dont add' }
        GivenAttributesAdded $newValue
        InCollection $value | Should -BeTrue
        InCollection $newValue | Should -BeTrue
    }

    It 'should throw error if no key is in hashtable' {
        $attributes = @{ 'value' = 'throw error' }
        { Add-CIisCollectionItem -LocationPath $script:locationPath `
                                -SectionPath 'system.webServer/httpProtocol' `
                                -CollectionName 'customHeaders' `
                                -Attribute $attributes `
                                -ErrorAction 'Stop'
        } | Should -Throw -ExpectedMessage "*because the unique key*"
    }
}