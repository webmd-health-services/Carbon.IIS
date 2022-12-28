
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:webServerCachingEnabled = ''
    $script:newEnabledValue = $true
    $script:webServerCachingEnableKernelCache = ''
    $script:newKernelCacheValue = $true
    $script:siteName = ''
    $script:testNum = 0

    function GivenWebsite
    {
        Install-CIisWebsite -Name $script:siteName -PhysicalPath 'C:\Inetpub\wwwroot'
    }

    function ThenAttributes
    {
        param(
            [hashtable] $SetTo = @{},

            [String[]] $DoesNotInclude = @(),

            [String[]] $ThatInheritValuesAre = @(),

            [String] $AtLocation
        )

        $locationPathArg = @{}
        if ($AtLocation)
        {
            $locationPathArg['LocationPath'] = $AtLocation
        }

        $updatedSection = Get-CIisConfigurationSection -SectionPath 'system.webServer/caching' @locationPathArg
        foreach ($name in $SetTo.Keys)
        {
            $updatedSection.GetAttributeValue($name) | Should -Be $SetTo[$name]
        }

        foreach ($missingAttr in $DoesNotInclude)
        {
            $updatedSection.Attributes[$missingAttr] | Should -BeNullOrEmpty
        }

        foreach ($name in $ThatInheritValuesAre)
        {
            $attrSchema = $updatedSection.Schema.AttributeSchemas[$name]
            $updatedSection.GetAttributeValue($name) |
                Should -Be $attrSchema.DefaultValue -Because "attribute ""$($name)"" should inherit value from default"
        }
    }

    function WhenSettingAttribute
    {
        param(
            [hashtable] $WithArg = @{}
        )

        if (-not $WithArg.ContainsKey('ConfigurationElement'))
        {
            $WithArg['SectionPath'] = 'system.webServer/caching'
        }
        Set-CIisConfigurationAttribute @WithArg
    }
}

AfterAll {
}

Describe 'Set-CIisConfigurationAttribute' {
    BeforeEach {
        $webServerCaching = Get-CIisConfigurationSection -SectionPath 'system.webServer/caching'

        $script:webServerCachingEnabled = $webServerCaching['enabled']
        $script:newEnabledValue = $true
        if ($script:webServerCachingEnabled)
        {
            $script:newEnabledValue = $false
        }

        $script:webServerCachingEnableKernelCache = $webServerCaching['enableKernelCache']
        $script:newKernelCacheValue = $true
        if ($script:webServerCachingEnableKernelCache)
        {
            $script:newKernelCacheValue = $false
        }

        $script:siteName = "Set-CIisConfigurationAttribute$($script:testNum)"
        $script:testNum += 1

        $Global:Error.Clear()

    }

    AfterEach {
        $Global:Error | Format-List * -Force | Out-String | Write-Debug

        Set-CIisConfigurationAttribute -SectionPath 'system.webServer/caching' `
                                       -Name 'enabled' `
                                       -Value $script:webServerCachingEnabled
        Set-CIisConfigurationAttribute -SectionPath 'system.webServer/caching' `
                                       -Name 'enableKernelCache' `
                                       -Value $script:webServerCachingEnableKernelCache

        Uninstall-CIisWebsite -Name $script:siteName
    }


    It 'should set global configuration section attribute using section path' {
        WhenSettingAttribute -WithArg @{ Name = 'enabled' ; Value = $script:newEnabledValue }
        ThenAttributes -SetTo @{ enabled = $script:newEnabledValue }
    }

    It 'should set multiple global configuration section attributes using section path' {
        $attrs = @{ 'enabled' = $script:newEnabledValue ; 'enableKernelCache' = $script:newKernelCacheValue ; }
        WhenSettingAttribute -WithArg @{ Attribute = $attrs }
        ThenAttributes -SetTo $attrs
    }

    It 'should fail if attribute does not exist' {
        WhenSettingAttribute -WithArg @{ Name = 'fubar' ; Value = 'snafu' ; ErrorAction = 'SilentlyContinue' }
        ThenAttributes -DoesNotInclude @('fubar')
        $Global:Error | Should -Match 'that attribute doesn''t exist on that element'
    }

    It 'should set global configuration section attribute using configuration element' {
        $element = Get-CIisConfigurationSection -SectionPath 'system.webServer/caching'
        $setArgs = @{ ConfigurationElement = $element ; Name = 'enabled' ; Value = $script:newEnabledValue }
        WhenSettingAttribute -WithArg $setArgs
        ThenAttributes -SetTo @{ 'enabled' =  $script:newEnabledValue }
    }

    It 'should set multiple global configuration section attributes using configuration element' {
        $attrs = @{ 'enabled' = $script:newEnabledValue ; 'enableKernelCache' = $script:newKernelCacheValue ; }
        $element = Get-CIisConfigurationSection -SectionPath 'system.webServer/caching'
        WhenSettingAttribute -WithArg @{ ConfigurationElement = $element ; Attribute = $attrs }
        ThenAttributes -SetTo $attrs
    }


    It 'should set location configuration section attribute' {
        GivenWebsite
        $setArgs = @{
            LocationPath = $script:siteName;
            Name = 'enabled';
            Value = $script:newEnabledValue;
        }
        WhenSettingAttribute -WithArg $setArgs
        ThenAttributes -SetTo @{ 'enabled' = $script:newEnabledValue } -AtLocation $script:siteName
    }

    It 'should set multiple location configuration section attributes' {
        GivenWebsite
        $attrs = @{ 'enabled' = $script:newEnabledValue ; 'enableKernelCache' = $script:newKernelCacheValue ; }
        WhenSettingAttribute -WithArg @{ LocationPath = $script:siteName ; Attribute = $attrs ; }
        ThenAttributes -SetTo $attrs -AtLocation $script:siteName
    }

    It 'should resetting all attributes' {
        GivenWebsite
        $attrs = @{ 'enabled' = $script:newEnabledValue ; 'enableKernelCache' = $script:newKernelCacheValue ; }
        WhenSettingAttribute -WithArg @{ LocationPath = $script:siteName ; Attribute = $attrs ; }
        WhenSettingAttribute -WithArg @{ LocationPath = $script:siteName ; Attribute = @{} ; Reset = $true ; }
        WhenSettingAttribute -WithArg @{ LocationPath = $script:siteName ; Attribute = @{} ; Reset = $true ; }
        ThenAttributes -ThatInheritValuesAre @( 'enabled', 'enableKernelCache')
    }
}