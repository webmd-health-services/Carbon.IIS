
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

Describe 'Join-CIisPath' {
    BeforeAll {
        & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)
    }

    It 'should join paths' {
        Join-CIisPath 'SiteName' 'Virtual'  | Should -Be 'SiteName/Virtual'
        Join-CIisPath 'SiteName/' 'Virtual' | Should -Be 'SiteName/Virtual'
        Join-CIisPath 'SiteName/' '/Virtual' | Should -Be 'SiteName/Virtual'
        Join-CIisPath 'SiteName' '/Virtual' | Should -Be 'SiteName/Virtual'
        Join-CIisPath 'SiteName\' 'Virtual' | Should -Be 'SiteName/Virtual'
        Join-CIisPath 'SiteName\' '\Virtual' | Should -Be 'SiteName/Virtual'
        Join-CIisPath 'SiteName' '\Virtual' | Should -Be 'SiteName/Virtual'
        Join-CIisPath 'SiteName' '' | Should -Be 'SiteName'
        'SiteName' | Join-CIisPath | Should -Be 'SiteName'
        'SiteName', '' | Join-CIisPath | Should -Be 'SiteName'
        'SiteName', '', 'path1' | Join-CIisPath | Should -Be 'SiteName/path1'
        'SiteName', '.', '..', '\path1\' | Join-CIisPath | Should -Be 'path1'
        Join-CIisPath -Path 'one' 'two' 'three' 'four' 'five' | Should -Be 'one/two/three/four/five'
        Join-CIisPath -Path 'one', 'two', 'three', 'four', 'five' | Should -Be 'one/two/three/four/five'
        Join-CIisPath -Path '/', 'VOne' | Should -Be 'VOne'
        Join-CIisPath -Path '/' | Should -Be ''
        Join-CIisPath -Path '/' -LeadingSlash | Should -Be '/'
    }

}
