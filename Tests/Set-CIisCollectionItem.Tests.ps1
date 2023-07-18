BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonAddIisCollectionItem'
    $script:sitePort = 47038
    $script:testDir = $null

    function GivenValueAdded {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string] $Value
        )

        Set-CIisCollectionItem -LocationPath $script:locationPath `
                               -SectionPath 'system.webServer/httpProtocol' `
                               -CollectionName 'customHeaders' `
                               -Value $Value
    }

    function GivenAttributesAdded {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [object] $Value,

            [Parameter(Mandatory)]
            [hashtable] $Attribute
        )

        Set-CIisCollectionItem -LocationPath $script:locationPath `
                               -SectionPath 'system.webServer/httpProtocol' `
                               -CollectionName 'customHeaders' `
                               -Value $Value `
                               -Attribute $Attribute
    }

    function InCollection {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [Object] $Value,

            [hashtable] $Item
        )

        $collection = Get-CIisCollection -LocationPath $script:locationPath `
                                         -SectionPath 'system.webServer/httpProtocol' `
                                         -Name 'customHeaders'
        $collectionKey = Get-CIisCollectionKeyName -Collection $collection

        $itemExists = $false
        foreach ($collectionItem in $collection)
        {
            if ($Value)
            {
                if ($collectionItem.GetAttributeValue($collectionKey) -eq $Value)
                {
                    $itemExists = $true
                }
            }
            if ($Item)
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

                if ($allFieldsMatch -and $itemExists)
                {
                    break
                }
                else
                {
                    $itemExists = $false
                }
            }
        }
        return $itemExists
    }

    function ThenError
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string] $ErrorMessage
        )

        {
            Set-CIisCollectionItem -LocationPath $script:locationPath `
                                   -SectionPath 'system.webServer/httpProtocol' `
                                   -CollectionName 'customHeaders' `
                                   -Value 'Error Out' `
                                   -ErrorAction 'Stop'
        } | Should -Throw -ExpectedMessage $ErrorMessage
    }
}


Describe 'Set-CIisCollectionItem' {
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
        InCollection -Value $value | Should -BeTrue
    }

    It 'should successfully add item if hashtable provided' {
        $attributes = @{ 'value' = 'dont add' }
        GivenAttributesAdded -Value 'X-AddIisItem' -Attribute $attributes
        InCollection -Value 'X-AddIisItem' -Item $attributes | Should -BeTrue
    }

    It 'should overwrite item if it already exists' {
        $attributes = @{ 'value' = 'overwrite me' }
        GivenAttributesAdded -Value 'X-AddIisItem' -Attribute $attributes
        InCollection -Value 'X-AddIisItem' -Item $attributes | Should -BeTrue

        $newAttrs = @{ 'value' = 'overwritten' }
        GivenAttributesAdded -Value 'X-AddIisItem' -Attribute $newAttrs
        InCollection -Value 'X-AddIisItem' -Item $newAttrs | Should -BeTrue
        InCollection -Value 'X-AddIisItem' -Item $attributes | Should -BeFalse
    }

    It 'should throw warning if key is in hashtable' {
        $attributes = @{
            'name' = 'name'
            'value' = 'throw error'
        }
        { Set-CIisCollectionItem -LocationPath $script:locationPath `
                                -SectionPath 'system.webServer/httpProtocol' `
                                -CollectionName 'customHeaders' `
                                -Value 'X-Carbon-AddCollectionItem' `
                                -Attribute $attributes `
                                -WarningAction 'Stop'
        } | Should -Throw -ExpectedMessage "*as the Value parameter.*"
    }

    It 'should fail if key not found' {
        Mock -CommandName 'Get-CIisCollectionKeyName' -ModuleName 'Carbon.IIS'
        ThenError -ErrorMessage '*not found*'
    }
}