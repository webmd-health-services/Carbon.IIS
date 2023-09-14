BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = ''
    $script:sitePort = 47038
    $script:testDir = $null

    function WhenSetting {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [Object] $Value
        )

        $Value | Set-CIisCollectionItem -LocationPath $script:locationPath `
                                        -SectionPath 'system.webServer/httpProtocol' `
                                        -CollectionName 'customHeaders'
    }

    function ThenCollectionIs {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [hashtable[]] $Value
        )

        $collection = Get-CIisCollection -LocationPath $script:locationPath `
                                         -SectionPath 'system.webServer/httpProtocol' `
                                         -Name 'customHeaders'
        $collection | Should -HaveCount $Value.Length
        for ($idx = 0 ; $idx -lt $Value.Length ; ++$idx)
        {
            $actualValue = $collection[$idx]
            $expectedValue = $Value[$idx]

            $actualValue.Attributes.Count | Should -Be $expectedValue.Count
            foreach ($key in $expectedValue.Keys)
            {
                $actualValue.GetAttributeValue($key) | Should -Be $expectedValue[$key]
            }
        }
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
        $Global:Error.Clear()
        $script:testDir = New-TestDirectory
        $script:locationPath = "Set-CIisCollectionItem-$([IO.Path]::GetRandomFileName())"
        Install-CIisWebsite -Name $script:locationPath -Path $script:testDir -Binding "http/*:$($script:sitePort):*"
        Disable-CIisCollectionInheritance -SectionPath 'system.webServer/httpProtocol' `
                                          -Name 'customHeaders' `
                                          -LocationPath $script:locationPath
    }

    AfterEach {
        Resume-CIisAutoCommit
        Uninstall-CIisWebsite -Name $script:locationPath
    }

    It 'adds item' {
        $attribute = @{ 'name' = 'X-AddIisItem' ; 'value' = 'dont add' }
        WhenSetting $attribute
        ThenCollectionIs $attribute
    }

    It 'replaces value on existing item' {
        $attribute = @{ 'name' = 'X-AddIisItem' ; 'value' = 'overwrite me' }
        WhenSetting $attribute
        ThenCollectionIs $attribute

        $attribute = @{ 'name' = 'X-AddIisItem' ; 'value' = 'overwritten' }
        WhenSetting $attribute
        ThenCollectionIs @{ 'name' = 'X-AddIisItem' ; 'value' = 'overwritten' }
    }

    It 'sets collection item on a configuration element' {
        Uninstall-CIisWebsite -Name $script:locationPath
        Suspend-CIisAutoCommit
        $site = Install-CIisWebsite -Name $script:locationPath `
                                    -Path $script:testDir `
                                    -Binding "http/*:${script:sitePort}:*" `
                                    -PassThru
        $customFields = $site.LogFile.CustomLogFields
        $customFields | Should -HaveCount 0
        @{ logFieldName = 'logFieldName' ; sourceName = 'sourceName' ; sourceType = 'RequestHeader' } |
            Set-CIisCollectionItem -ConfigurationElement $customFields

        $customFields | Should -HaveCount 1
        $customFields[0].LogFieldName | Should -Be 'logFieldName'
        $customFields[0].SourceName | Should -Be 'sourceName'
        $customFields[0].SourceType | Should -Be 'RequestHeader'

        @(
            @{ logFieldName = 'logFieldName' ; sourceName = 'sourceNameb' ; sourceType = 'ResponseHeader' },
            @{ logFieldName = 'logFieldName2' ; sourceName = 'sourceName2' ; sourceType = 'RequestHeader' }

        ) |
            Set-CIisCollectionItem -ConfigurationElement $customFields

        $customFields | Should -HaveCount 2
        $customFields[0].LogFieldName | Should -Be 'logFieldName'
        $customFields[0].SourceName | Should -Be 'sourceNameb'
        $customFields[0].SourceType | Should -Be 'ResponseHeader'
        $customFields[1].LogFieldName | Should -Be 'logFieldName2'
        $customFields[1].SourceName | Should -Be 'sourceName2'
        $customFields[1].SourceType | Should -Be 'RequestHeader'
    }

    It 'ignores missing attributes' {
        $site = Get-CIisWebsite -Name $script:locationPath
        $attrs = @{ logFieldName = 'Content-Type' ; sourceName = 'OriginalValue' ; sourceType = 0 ; }
        $attrs | Set-CIisCollectionItem -ConfigurationElement $site.LogFile.CustomLogFields

        $site = Get-CIisWebsite -Name $script:locationPath
        $customField = $site.LogFile.CustomLogFields[0]
        $customField.LogFieldName | Should -Be $attrs['logFieldName']
        $customField.SourceName | Should -Be $attrs['sourceName']
        $customField.SourceType | Should -Be $attrs['sourceType']

        $attrs.Remove('sourceName')
        $attrs | Set-CIisCollectionItem -ConfigurationElement $site.LogFile.CustomLogFields

        $site = Get-CIisWebsite -Name $script:locationPath
        $customField = $site.LogFile.CustomLogFields[0]
        $customField.LogFieldName | Should -Be $attrs['logFieldName']
        $customField.SourceName | Should -Be 'OriginalValue'
        $customField.SourceType | Should -Be $attrs['sourceType']

    }

    It 'removes missing attributes' {
        $site = Get-CIisWebsite -Name $script:locationPath
        $attrs = @{ logFieldName = 'Content-Type' ; sourceName = 'OriginalValue' ; sourceType = 0 ; }
        $attrs | Set-CIisCollectionItem -ConfigurationElement $site.LogFile.CustomLogFields

        $site = Get-CIisWebsite -Name $script:locationPath
        $customField = $site.LogFile.CustomLogFields[0]
        $customField.LogFieldName | Should -Be $attrs['logFieldName']
        $customField.SourceName | Should -Be $attrs['sourceName']
        $customField.SourceType | Should -Be $attrs['sourceType']

        $attrs.Remove('sourceName')
        { $attrs | Set-CIisCollectionItem -ConfigurationElement $site.LogFile.CustomLogFields -Strict } |
            Should -Throw '*the request is not supported*'

        $site = Get-CIisWebsite -Name $script:locationPath
        $customField = $site.LogFile.CustomLogFields[0]
        $customField.LogFieldName | Should -Be $attrs['logFieldName']
        $customField.SourceName | Should -Be 'OriginalValue'
        $customField.SourceType | Should -Be $attrs['sourceType']
    }
}
