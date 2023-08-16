
using namespace Microsoft.Web.Administration

Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testNum = 0

    function GivenWebsite
    {
        param(
            [String[]] $WithBinding
        )

        Install-CIisWebsite -Name $script:siteName -PhysicalPath (New-TestDirectory) -Binding $WithBinding
    }

    function ThenBinding
    {
        param(
            [String] $Binding,

            [Microsoft.Web.Administration.SslFlags] $HasSslFlags
        )

        $sslFlags =
            Get-CIisWebsite -Name $script:siteName |
            Select-Object -ExpandProperty 'Bindings' |
            Where-Object 'BindingInformation' -EQ $Binding |
            Select-Object -ExpandProperty 'SslFlags'

        $sslFlags | Should -Be $HasSslFlags
    }

    function WhenSetting
    {
        [CmdletBinding()]
        param(
            [Microsoft.Web.Administration.SslFlags] $SslFlag,

            [hashtable] $WithArgs = @{}
        )

        Set-CIisWebsiteBinding -SiteName $script:siteName -SslFlag $SslFlag @WithArgs
    }
}

Describe 'Set-CIisWebsiteBinding' {
    BeforeAll {
        Start-W3ServiceTestFixture
        Install-CIisAppPool -Name 'Set-CIisWebsiteBinding'
        Get-CIisWebsite | Where-Object 'Name' -Like 'Set-CIisWebsiteBinding*' | Uninstall-CIisWebsite
    }

    AfterAll {
        Get-CIisWebsite | Where-Object 'Name' -Like 'Set-CIisWebsiteBinding*' | Uninstall-CIisWebsite
        Uninstall-CIisAppPool -Name 'Set-CIisWebsiteBinding'
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $Global:Error.Clear()
        $script:siteName = "Set-CIisWebsiteBinding$($script:testNum)"
    }

    AfterEach {
        $script:testNum++
    }

    It 'updates SSL flags' {
        GivenWebsite -WithBinding 'https/*:65534:example.com'
        WhenSetting -SslFlag Sni
    }

    It 'only updates hostname bindings with Sni flag' {
        GivenWebsite -WithBinding 'http/*:65533:example.com','https/*:65532:','https/*:65531:example.com'
        WhenSetting -SslFlag Sni -ErrorAction SilentlyContinue
        ThenError -Matches 'unable to set SSL flags for binding "\*:65532:"'
        ThenBinding '*:65533:example.com' -HasSslFlags None
        ThenBinding '*:65532:' -HasSslFlags None
        ThenBinding '*:65531:example.com' -HasSslFlags Sni
    }

    It 'should support WhatIf' {
        GivenWebsite -WithBinding 'https/*:65530:example.com'
        WhenSetting -SslFlag Sni -WithArgs @{ WhatIf = $true }
        ThenBinding '*:65530:example.com' -HasSslFlags None
    }

    It 'only updates when configuration changes' {
        GivenWebsite -WithBinding 'https/*:65529:example.com'
        WhenSetting -SslFlag Sni
        ThenBinding '*:65529:example.com' -HasSslFlags Sni
        Mock -CommandName 'Save-CIisConfiguration' -ModuleName 'Carbon.IIS'
        WhenSetting -SslFlag Sni
        Should -Not -Invoke 'Save-CIisConfiguration' -ModuleName 'Carbon.IIS'
    }

    It 'updates specific binding' {
        GivenWebsite -WithBinding 'https/*:65528:example.com', 'https/*:65527:'
        WhenSetting -SslFlag Sni -WithArgs @{ BindingInformation = '*:65528:example.com' }
        ThenBinding '*:65528:example.com' -HasSslFlags Sni
        ThenBinding '*:65527:' -HasSslFlags None
    }

    It 'accepts bindings as input' {
        GivenWebsite -WithBinding 'https/*:65526:example.com', 'https/*:65525:example.com', 'https/*:65524:'
        Get-CIisWebsite -Name $script:siteName |
            Select-Object -ExpandProperty 'Bindings' |
            Where-Object 'Protocol' -EQ 'https' |
            Where-Object 'Host' -NE '' |
            Set-CIisWebsiteBinding -SiteName $script:siteName -SslFlag Sni
        ThenBinding '*:65526:example.com' -HasSslFlags Sni
        ThenBinding '*:65525:example.com' -HasSslFlags Sni
        ThenBinding '*:65524:' -HasSslFlags None
    }
}
