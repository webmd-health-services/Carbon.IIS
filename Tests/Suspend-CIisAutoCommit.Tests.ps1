
using namespace Microsoft.Web.Administration

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testDir = ''
    $script:name = ''
}

Describe 'Suspend-CIisAutoCommit' {
    BeforeEach {
        $Global:Error.Clear()
        $script:testDir = $TestDrive
        $script:name = "Suspend-CIisAutoCommit-$([IO.Path]::GetRandomFileName())"
    }

    AfterEach {
        Resume-CIisAutoCommit -Save
        Uninstall-CIisWebsite -Name $script:name
        Uninstall-CIisAppPool -Name $script:name
    }

    It 'stops saving changes' {
        $appHostPath =Join-Path -Path ([Environment]::GetFolderPath('System')) `
                                -ChildPath 'inetsrv\config\applicationHost.config' `
                                -Resolve
        $appHostInfo = Get-Item -Path $appHostPath
        $expectedLastWriteTime = $appHostInfo.LastWriteTime
        Start-Sleep -Seconds 1
        Suspend-CIisAutoCommit

        Install-CIisAppPool -Name $script:name
        (Get-Item -Path $appHostPath).LastWriteTime | Should -Be $expectedLastWriteTime
        $site = Install-CIisWebsite -Name $script:name -PhysicalPath $script:testDir -AppPoolName $script:name -PassThru
        (Get-Item -Path $appHostPath).LastWriteTime | Should -Be $expectedLastWriteTime

        $customFields = $site.LogFile.CustomLogFields
        $xpath = "/configuration/system.applicationHost/sites/site[@id = $($site.Id)]/logFile/customFields"
        Disable-CIisCollectionInheritance -ConfigurationElement $customFields -CollectionElementXPath $xpath
        @(
            'Content-Type',
            'CLIENT-CERT-NOTAFTER',
            'CLIENT-CERT-SERIAL',
            'CLIENT-CERT-SUBJECT',
            'CLIENT-CERT-ISSUER',
            'c-tp',
            'cert_header',
            'mycert'
        ) |
            ForEach-Object { @{ logFieldName = $_ ; sourceName = $_ ; sourceType = 'RequestHeader'} } |
            Set-CIisCollection -ConfigurationElement $customFields
        # $customFields.Clear()
        # [void]$customFields.Add('Content-Type', 'Content-Type', 'RequestHeader')
        # [void]$customFields.Add('CLIENT-CERT-NOTAFTER', 'CLIENT-CERT-NOTAFTER', 'RequestHeader')
        # [void]$customFields.Add('CLIENT-CERT-SERIAL', 'CLIENT-CERT-SERIAL', 'RequestHeader')
        # [void]$customFields.Add('CLIENT-CERT-SUBJECT', 'CLIENT-CERT-SUBJECT', 'RequestHeader')
        # [void]$customFields.Add('CLIENT-CERT-ISSUER', 'CLIENT-CERT-ISSUER', 'RequestHeader')
        # [void]$customFields.Add('c-tp', 'c-tp', 'RequestHeader')
        # [void]$customFields.Add('cert_header', 'cert_header', 'RequestHeader')
        # [void]$customFields.Add('mycert', 'mycert', 'RequestHeader')
        Save-CIisConfiguration
        (Get-Item -Path $appHostPath).LastWriteTime | Should -Be $expectedLastWriteTime

        Resume-CIisAutoCommit
        (Get-Item -Path $appHostPath).LastWriteTime | Should -Be $expectedLastWriteTime

        Resume-CIisAutoCommit -Save
        (Get-Item -Path $appHostPath).LastWriteTime | Should -BeGreaterThan $expectedLastWriteTime
    }
}