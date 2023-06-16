BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonAddIisHttpHeader'
    $script:sitePort = 47038
    $script:testDir = $null

    function ThenExists
    {
        [CmdletBinding()]
        param(
            [string] $Name,
            [string] $Value,
            [switch] $Not
        )

        $customHeaders = Get-CIisCollection -LocationPath $script:locationPath `
                                         -SectionPath 'system.webServer/httpProtocol' `
                                         -Name 'customHeaders'

        $matchesParams = $customHeaders |
            Where-Object {
                $_.GetAttributeValue('name') -eq $Name -and
                $_.GetAttributeValue('value') -eq $Value
            }

        if ($Not)
        {
            $matchesParams | Should -BeNullOrEmpty
        }
        else
        {
            $matchesParams | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Add-CIisHttpHeader' {
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

    It 'should add http header to collection' {
        $name = 'X-AddHttpHeader'
        $value = 'Added'

        Add-CIisHttpHeader -Name $name -Value $value -LocationPath $script:locationPath
        ThenExists -Name $name -Value $value
    }

    It 'should overwrite previous if there are duplicates' {
        $name = 'X-AddHttpHeader'
        $firstValue = 'FirstAdd'

        Add-CIisHttpHeader -Name $name -Value $value -LocationPath $script:locationPath
        ThenExists -Name $name -Value $value
        $secondValue = 'SecondAdd'
        Add-CIisHttpHeader -Name $name -Value $secondValue -LocationPath $script:locationPath
        ThenExists -Name $name -Value $value -Not
        ThenExists -Name $name -Value $secondValue
    }
}