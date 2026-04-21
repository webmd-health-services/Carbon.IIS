BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:locationPath = 'CarbonRemoveIisCollectionItem'
    $script:sitePort = 47038
    $script:testDir = $null


    function ThenCollection
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $At,
            [String] $Named,
            [String] $For,
            [switch] $Not,
            [String] $UsingKey = 'name',
            [Alias('WithValue')]
            [string] $HasValue
        )

        $getArgs = @{}
        if ($For)
        {
            $getArgs['LocationPath'] = $For
        }

        if ($Named)
        {
            $getArgs['Name'] = $Named
        }

        $collection = Get-CIisCollection -SectionPath $At @getArgs
        $item = $collection | Where-Object { $_.GetAttributeValue($UsingKey) -eq $HasValue }

        if ($Not)
        {
            $item | Should -BeNullOrEmpty
        }
        else
        {
            $item | Should -Not -BeNullOrEmpty
        }
    }

    function GivenCollection
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $At,

            [String] $Named,

            [string] $For,

            [String] $UsingKey,

            [Object[]] $WithValue
        )

        $setArgs = @{
            SectionPath = $At
        }
        if ($For)
        {
            $setArgs['LocationPath'] = $For
        }

        if ($Named)
        {
            $setArgs['CollectionName'] = $Named
        }

        if ($UsingKey)
        {
            $setArgs['UniqueKeyAttributeName'] = $UsingKey
        }

        $WithValue | Set-CIisCollectionItem @setArgs
    }

    function WhenUninstalling
    {
        [CmdletBinding()]
        param(
            [hashtable] $WithArgs = @{}
        )

        Uninstall-CIisCollectionItem @WithArgs
    }
}

Describe 'Uninstall-CIisCollectionItem' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:locationPath -Path $script:testDir -Binding "http/*:$($script:sitePort):*"
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:locationPath
    }

    It 'uninstalls' {
        $value = 'X-RemoveItem'
        GivenCollection 'system.webServer/httpProtocol' `
                        -Named 'customHeaders' `
                        -For $script:locationPath `
                        -WithValue 'random-item'
        WhenUninstalling -WithArgs @{
            SectionPath = 'system.webServer/httpProtocol'
            CollectionName = 'customHeaders'
            LocationPath = $script:locationPath
            Value = 'random-item'
        }
        ThenCollection 'system.webServer/httpProtocol' `
                       -Named 'customHeaders' `
                       -For $script:locationPath `
                       -Not `
                       -HasValue $value
    }

    It 'handles item already uninstalled' {
        ThenCollection 'system.webServer/httpProtocol' `
                       -Named 'customHeaders' `
                       -For $script:locationPath `
                       -Not `
                       -HasValue 'X-NonExistent'
        {
            WhenUninstalling -WithArgs @{
                LocationPath = $script:locationPath
                SectionPath = 'system.webServer/httpProtocol'
                CollectionName = 'customHeaders'
                Value = 'X-NonExistent'
                ErrorAction = 'Stop'
            }
        } | Should -Not -Throw
        ThenCollection 'system.webServer/httpProtocol' `
                       -Named 'customHeaders' `
                       -For $script:locationPath `
                       -Not `
                       -HasValue 'X-NonExistent'
    }

    It 'removes complex value' {
        GivenCollection 'system.webServer/httpErrors' `
                        -For $script:locationPath `
                        -UsingKey 'statusCode' `
                        -WithValue @{
                                statusCode = 401
                                prefixLanguageFilePath = '%SystemDrive%\inetpub\custerr'
                                path = '401.htm'
                            }
        {
            WhenUninstalling -WithArgs @{
                LocationPath = $script:locationPath
                SectionPath = 'system.webServer/httpErrors'
                Value = '401'
                UniqueKeyAttributeName = 'statusCode'
                ErrorAction = 'Stop'
            }
        } | Should -Not -Throw -ExpectedMessage '*doesn''t have a unique key attribute*'
        ThenCollection 'system.webServer/httpErrors' `
                       -For $script:locationPath `
                       -UsingKey 'statusCode' `
                       -Not `
                       -HasValue '401'
    }

    It 'validates collection key name' {
        {
            WhenUninstalling -WithArgs @{
                LocationPath = $script:locationPath
                SectionPath = 'system.webServer/httpErrors'
                Value = 'does-not-exist'
                ErrorAction = 'Stop'
            }
        } | Should -Throw -ExpectedMessage '*doesn''t have a unique key attribute*'
    }

    It 'uninstalls using a configuration element object' {
        Add-CIisHttpHeader -Name 'Uninstall-CIisCollectionItem' -Value 'from configuration element'
        $section = Get-CIisConfigurationSection -SectionPath 'system.webServer/httpProtocol' `
                                                -LocationPath $script:locationPath
        $section | Should -Not -BeNullOrEmpty

        WhenUninstalling -WithArgs @{
            ConfigurationElement = $section
            CollectionName = 'customHeaders'
            Value = 'Uninstall-CIisCollectionItem'
            LocationPath = $script:locationPath
        }
        ThenCollection 'system.webServer/httpProtocol' `
                       -Named 'customHeaders' `
                       -For $script:locationPath `
                       -Not `
                       -HasValue 'Uninstall-CIisCollectionItem'
    }
}