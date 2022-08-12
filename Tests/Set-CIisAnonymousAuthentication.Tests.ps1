
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    $script:port = 9877
    $script:webConfigPath = ''
    $script:siteName = $PSCommandPath | Split-Path -Leaf
    $script:testWebRoot = ''

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    function GivenVirtualPath
    {
        param(
            [Parameter(Mandatory)]
            [String] $Path
        )

        New-Item -Path (Join-Path -Path $script:testWebRoot -ChildPath $Path) -ItemType 'Directory'
    }

    function ThenAttributesSetTo
    {
        param(
            [String] $ForVirtualPath = '',

            [hashtable] $ExpectedValues = @{},

            [switch] $Defaults
        )

        $sectionPath = 'system.webServer/security/authentication/anonymousAuthentication'

        if( $Defaults )
        {
            $section = Get-CIisConfigurationSection -SectionPath $sectionPath
            foreach( $attr in $section.Attributes )
            {
                if( $ExpectedValues.ContainsKey($attr.Name) )
                {
                    continue
                }

                $ExpectedValues[$attr.Name] = $attr.Value
            }
        }

        $section = Get-CIisConfigurationSection -SiteName $script:siteName `
                                                -VirtualPath $ForVirtualPath `
                                                -SectionPath $sectionPath
        foreach( $attrName in $ExpectedValues.Keys )
        {
            $expectedValue = $ExpectedValues[$attrName]
            if( $expectedValue -is [SecureString] )
            {
                $expectedValue = [pscredential]::New('i', $expectedValue).GetNetworkCredential().Password
            }
            $section.GetAttributeValue($attrName) | Should -Be $expectedValue
        }
    }

    function ThenCommittedToAppHost
    {
        $script:webConfigPath | Should -Not -Exist # make sure committed to applicationHost.config
    }

    function WhenSetting
    {
        param(
            [hashtable] $WithArgument = @{}
        )

        $Global:Error.Clear()
        Set-CIisAnonymousAuthentication -SiteName $script:siteName @WithArgument
    }
}

Describe 'Set-CIisAnonymousAuthentication' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testWebRoot = New-TestDirectory
        Install-CIisWebsite -Name $script:siteName -Path $script:testWebRoot -Bindings "http://*:$($script:port)"
        $script:webConfigPath = Join-Path -Path $script:testWebRoot -ChildPath 'web.config'
        if( Test-Path $script:webConfigPath )
        {
            Remove-Item $script:webConfigPath
        }
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should set attributes' {
        $setArgs = @{
            Enabled = $true;
            LogonMethod = [Microsoft.Web.Administration.AuthenticationLogonMethod]::Interactive;
            Password = (ConvertTo-SecureString -String 'iqhz434wsy3' -AsPlainText -Force);
            UserName = 'spexf0xiotr';
        }
        WhenSetting -WithArgument $setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo $setArgs
    }

    It 'should set attributes on virtual path' {
        $setArgs = @{
            Enabled = $false;
            LogonMethod = [Microsoft.Web.Administration.AuthenticationLogonMethod]::Batch;
            Password = (ConvertTo-SecureString -String '2w1epswgv0i' -AsPlainText -Force);
            UserName = 'qy33lcg23iy';
            VirtualPath = 'somepath';
        }
        GivenVirtualPath 'somepath'
        WhenSetting -WithArgument $setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo -Defaults
        $setArgs.Remove('VirtualPath')
        ThenAttributesSetTo -ForVirtualPath 'somepath' $setArgs
    }

    It 'should support WhatIf' {
        $setArgs = @{
            Enabled = $true;
            LogonMethod = [Microsoft.Web.Administration.AuthenticationLogonMethod]::Network;
            Password = (ConvertTo-SecureString -String 'c0i0jga4qzo' -AsPlainText -Force);
            UserName = 'jpl2djwmzw4';
            WhatIf = $true;
        }
        WhenSetting -WithArgument $setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo -Defaults
    }

    It 'should not update if values have not changed' {
        $setArgs = @{
            Enabled = $false;
            LogonMethod = [Microsoft.Web.Administration.AuthenticationLogonMethod]::ClearText;
            Password = (ConvertTo-SecureString -String 'phnqkjngl0e' -AsPlainText -Force);
            UserName = 'rjgthuat4pm';
        }
        WhenSetting -WithArgument $setArgs
        ThenCommittedToAppHost
        ThenAttributesSetTo $setArgs
        $appHostConfigPath =
            Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config' -Resolve
        $appHostUpdatedAt = Get-Item -Path $appHostConfigPath
        WhenSetting -WithArgument $setArgs
        Get-Item -Path $appHostConfigPath |
            Select-Object -ExpandProperty 'LastWriteTimeUtc' |
            Should -Be $appHostUpdatedAt.LastWriteTimeUtc
    }
}
