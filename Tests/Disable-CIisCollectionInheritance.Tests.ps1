
#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:testNum = 0
    $script:testDir = $null
    $script:name = ''

    function ThenInheritanceDisabled
    {
        param(
            [String] $Named,
            [String] $InSection,
            [String] $ForLocation
        )

        $xpath = $InSection
        if ($Named)
        {
            $xpath = "${xpath}/${Named}"
        }
        $xpath = "${xpath}/clear"

        InModuleScope 'Carbon.IIS' {
            param(
                $XPath,
                $LocationPath
            )

            Test-CIisApplicationHostElement -XPath $XPath -LocationPath $LocationPath
        } -ArgumentList @($xpath, $ForLocation) |
            Should -BeTrue
    }
}

Describe 'Disable-CIisCollectionInheritance' {
    BeforeEach {
        $Global:Error.Clear()

        $script:testDir = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-Item -Path $script:testDir -ItemType 'Directory'

        $script:name = "Disable-CIisCollectionInheritance$([IO.Path]::GetRandomFileName())"
        Install-CIisWebsite -Name $script:name -PhysicalPath $script:testDir
    }

    AfterEach {
        $script:testNum += 1

        Uninstall-CIisWebsite -Name $script:name
    }

    It 'adds clear element to collection' {
        $locationArg = @{ LocationPath = $script:name }
        $sectionPath = 'system.webServer/httpProtocol'
        $collectionName = 'customHeaders'

        Disable-CIisCollectionInheritance -SectionPath $sectionPath @locationArg -Name $collectionName

        ThenInheritanceDisabled $collectionName -InSection $sectionPath -ForLocation $script:name
    }

   It 'handles already cleared collection' {
        $headerName = [IO.Path]::GetRandomFileName()
        $header2Name = [IO.Path]::GetRandomFileName()

        $locationArg = @{ LocationPath = $script:name }
        $sectionPath = 'system.webServer/httpProtocol'
        $collectionName = 'customHeaders'

        Disable-CIisCollectionInheritance -SectionPath $sectionPath @locationArg -Name $collectionName
        ThenInheritanceDisabled $collectionName -InSection $sectionPath -ForLocation $script:name

        Add-CIisHttpHeader @locationArg -Name $headerName -Value $headerName
        Add-CIisHttpHeader @locationArg -Name $header2Name -Value $header2Name

        Mock 'Save-CIisConfiguration' -ModuleName 'Carbon.IIS'
        Disable-CIisCollectionInheritance -SectionPath $sectionPath @locationArg -Name $collectionName
        Should -Not -Invoke 'Save-CIisConfiguration' -ModuleName 'Carbon.IIS'
   }
}
