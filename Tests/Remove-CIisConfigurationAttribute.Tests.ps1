
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    $script:port = 9877
    $script:webConfigPath = ''
    $script:siteName = $PSCommandPath | Split-Path -Leaf
    $script:testWebRoot = ''
    $script:sectionPath = 'system.webServer/security/authentication/anonymousAuthentication'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    function GivenNonDefaultAttributes
    {
        param(
            [hashtable] $Values,

            [String] $ForVirtualPath = ''
        )

        if( -not $Values )
        {
            $Values = @{
                Enabled = $false;
                LogonMethod = [Microsoft.Web.Administration.AuthenticationLogonMethod]::Network;
                Password = (ConvertTo-SecureString -String 'iqhz434wsy3' -AsPlainText -Force);
                UserName = 'spexf0xiot';
            }
        }

        Set-CIisAnonymousAuthentication ($script:siteName,$ForVirtualPath | Join-CIisPath) @Values
    }

    function GivenVirtualPath
    {
        param(
            [Parameter(Mandatory)]
            [String] $Path
        )

        New-Item -Path (Join-Path -Path $script:testWebRoot -ChildPath $Path) -ItemType 'Directory'
    }

    function ThenAttributesSetToDefault
    {
        param(
            [String] $ForVirtualPath = ''
        )

        $section = Get-CIisConfigurationSection -SectionPath $script:sectionPath
        foreach( $attr in $section.Attributes )
        {
            $attr.Value | Should -Be $attr.Schema.DefaultValue
        }
    }

    function ThenAttributesSetTo
    {
        param(
            [hashtable] $Values,
            [String] $ForVirtualPath = ''
        )

        $section = Get-CIisConfigurationSection -LocationPath $script:siteName -SectionPath $script:sectionPath
        foreach( $attr in $section.Attributes )
        {
            $expectedValue = $Values[$attr.Name]
            if( $expectedValue -is [securestring] )
            {
                $expectedValue = [pscredential]::New('i', $expectedValue).GetNetworkCredential().Password
            }
            $attr.Value | Should -Be $expectedValue -Because $attr.Name
        }
    }

    function ThenCommittedToAppHost
    {
        $script:webConfigPath | Should -Not -Exist # make sure committed to applicationHost.config
    }

    function WhenRemoving
    {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Position=0)]
            [String[]] $Attributes = @('enabled', 'logonMethod', 'password', 'userName'),

            [String] $ForVirtualPath,

            [switch] $ByPiping
        )

        $locationPath = Join-CIisPath -Path $script:siteName, $ForVirtualPath
        $Global:Error.Clear()
        if( $ByPiping )
        {
            $Attributes |
                Remove-CIisConfigurationAttribute -LocationPath $locationPath  -SectionPath $script:sectionPath
        }
        else
        {
            Remove-CIisConfigurationAttribute -LocationPath $locationPath `
                                              -SectionPath $script:sectionPath `
                                              -Name $Attributes
        }
    }
}

Describe 'Remove-CIisConfigurationAttribute' {
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
        Copy-Item -Path 'C:\Windows\System32\inetsrv\config\applicationHost.config' `
                  -Destination (Join-Path -Path $PSScriptRoot -ChildPath '..\.output')
        Uninstall-CIisWebsite -Name $script:siteName
    }

    It 'should remove attributes' {
        # All not default values.
        GivenNonDefaultAttributes
        WhenRemoving
        ThenCommittedToAppHost
        ThenAttributesSetToDefault
    }

    It 'should remove attributes by piping names' {
        GivenNonDefaultAttributes
        WhenRemoving -ByPiping
        ThenCommittedToAppHost
        ThenAttributesSetToDefault
    }

    It 'should remove attributes under virtual path' {
        $path = 'fdsjovfds'
        GivenVirtualPath $path
        GivenNonDefaultAttributes -ForVirtualPath $path
        WhenRemoving -ForVirtualPath $path
        ThenCommittedToAppHost
        ThenAttributesSetToDefault -ForVirtualPath $path
    }

    It 'should support WhatIf' {
        $setArgs = @{
            Enabled = $false;
            LogonMethod = [Microsoft.Web.Administration.AuthenticationLogonMethod]::Network;
            Password = (ConvertTo-SecureString -String 'c0i0jga4qzo' -AsPlainText -Force);
            UserName = 'jpl2djwmzw4';
        }
        GivenNonDefaultAttributes $setArgs
        WhenRemoving -WhatIf
        ThenCommittedToAppHost
        ThenAttributesSetTo $setArgs
    }

    It 'should not update if values have not changed' {
        $appHostConfigPath =
            Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config' -Resolve
        $appHostInfo = Get-Item -Path $appHostConfigPath
        Start-Sleep -Seconds 1
        WhenRemoving
        (Get-Item -Path $appHostConfigPath).LastWriteTimeUtc | Should -Be $appHostInfo.LastWriteTimeUtc
    }

}
