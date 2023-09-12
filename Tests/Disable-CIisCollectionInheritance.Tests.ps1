
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:testNum = 0
    $script:testDir = $null
    $script:name = ''

    function ThenInheritanceDisabled
    {
        [CmdletBinding(DefaultParameterSetName='BySectionPath')]
        param(
            [Parameter(Position=0, ParameterSetName='BySectionPath')]
            [String] $Named,

            [Parameter(Mandatory, ParameterSetName='BySectionPath')]
            [String] $InSection,

            [Parameter(ParameterSetName='BySectionPath')]
            [String] $ForLocation,

            [Parameter(Mandatory, ParameterSetName='ByXPath')]
            [String] $AtXPath
        )

        if (-not $AtXPath)
        {
            $AtXPath = $InSection
            if ($Named)
            {
                $AtXPath = "${AtXPath}/${Named}"
            }
        }

        InModuleScope 'Carbon.IIS' {
            param(
                $XPath,
                $LocationPath
            )

            $testArgs = @{}
            if ($LocationPath)
            {
                $testArgs['LocationPath'] = $LocationPath
            }

            Test-CIisApplicationHostElement -XPath "${XPath}/clear" @testArgs
        } -ArgumentList @($AtXPath, $ForLocation) |
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

    It 'clears configuration element collections' {
        $site = Get-CIisWebsite -Name $script:name
        $xpath = "/configuration/system.applicationHost/sites/site[@id = $($site.Id)]/logFile/customFields"
        $collection = $site.LogFile.CustomLogFields
        Disable-CIisCollectionInheritance -ConfigurationElement $collection -CollectionElementXPath $xpath
        ThenInheritanceDisabled -AtXPath $xpath
    }
}
