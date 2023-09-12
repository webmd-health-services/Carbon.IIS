
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)
}

Describe 'Get-CIisCollectionItem' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
    }

    AfterEach {
    }

    It 'gets items from the collection not the collection itself' {
        Add-CIisHttpHeader -Name 'Get-CIisCollectionItem' -Value 'some value'
        $items = Get-CIisCollectionItem -SectionPath 'system.webServer/httpProtocol' `
                                        -CollectionName 'customHeaders'
        $items.GetType().FullName | Should -Be ([Object[]]::New(0).GetType().FullName)
        ,$items | Should -HaveType ([Object[]])
    }

}
