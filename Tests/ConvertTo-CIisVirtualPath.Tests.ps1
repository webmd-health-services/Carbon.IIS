
Describe 'ConvertTo-CIisVirtualPath' {
    BeforeAll {
        & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)
    }

    It 'should normalize paths' {
        'Site' | ConvertTo-CIisVirtualPath | Should -Be '/Site'
        'C:\Site' | ConvertTo-CIisVirtualPath | Should -Be '/Site'
        '/Site' | ConvertTo-CIisVirtualPath | Should -Be '/Site'
        '\Site' | ConvertTo-CIisVirtualPath | Should -Be '/Site'
        'One\\\\\Two\\\\Three\\\..\\\.\\Four' | ConvertTo-CIisVirtualPath | Should -Be '/One/Two/Four'
        '\Site\' | ConvertTo-CIisVirtualPath | Should -Be '/Site'
        '/Site' | ConvertTo-CIisVirtualPath -NoLeadingSlash | Should -Be 'Site'
        'Site/VDir' | ConvertTo-CIisVirtualPath -NoLeadingSlash | Should -Be 'Site/VDir'
        '' | ConvertTo-CIisVirtualPath | Should -Be '/'
        '%*?"%<>|%' | ConvertTo-CIisVirtualPath | Should -Be '/%*?"%<>|%'
        $null | ConvertTo-CIisVirtualPath | Should -Be '/'
    }
}