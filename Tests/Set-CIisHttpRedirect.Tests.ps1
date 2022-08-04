# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Set-StrictMode -Version 'Latest'

BeforeAll {
    $script:port = 9877
    $script:webConfigPath = ''
    $script:siteName = 'CarbonSetIisHttpRedirect'
    $script:testWebRoot = ''

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)


    function Read-Url
    {
        param(
            [String] $Path = ''
        )

        return [Net.WebClient]::New().DownloadString( "http://localhost:$($script:port)/$($Path)" )
    }

    function Assert-Redirects
    {
        param(
            [String] $Path = ''
        )

        $numTries = 0
        $maxTries = 5
        $content = ''
        do
        {
            try
            {
                $content = Read-Url $Path
                if( $content -match 'Example Domain' )
                {
                    break
                }
            }
            catch
            {
                Write-Verbose "Error downloading '$Path': $_"
            }
            $numTries++
            Start-Sleep -Milliseconds 100
        }
        while( $numTries -lt $maxTries )
    }
}

Describe 'Set-CIisHttpRedirect' {
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

    It 'should redirect site' {
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com'
        Assert-Redirects
        $script:webConfigPath | Should -Not -Exist # make sure committed to applicationHost.config
        $settings = Get-CIisHttpRedirect -SiteName $script:siteName
        $settings.GetAttributeValue('Enabled') | Should -BeTrue
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
        $settings.GetAttributeValue('exactDestination') | Should -BeFalse
        $settings.GetAttributeValue('childOnly') | Should -BeFalse
        $settings.GetAttributeValue('httpResponseStatus') | Should -Be 302
    }

    It 'should set redirect customizations' {
        Set-CIisHttpRedirect -SiteName $script:siteName `
                             -Destination 'http://www.example.com' `
                             -HttpResponseStatus 301 `
                             -ExactDestination `
                             -ChildOnly
        Assert-Redirects
        $settings = Get-CIisHttpRedirect -SiteName $script:siteName
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
        $settings.GetAttributeValue('httpResponseStatus') | Should -Be 301
        $settings.GetAttributeValue('exactDestination') | Should -BeTrue
        $settings.GetAttributeValue('childOnly') | Should -BeTrue
    }

    It 'should set to default values' {
        Set-CIisHttpRedirect -SiteName $script:siteName `
                             -Destination 'http://www.example.com' `
                             -HttpResponseStatus 302 `
                             -ExactDestination `
                             -ChildOnly
        Assert-Redirects
        Set-CIisHttpRedirect -SiteName $script:siteName -Destination 'http://www.example.com'
        Assert-Redirects

        $settings = Get-CIisHttpRedirect -SiteName $script:siteName
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
        $settings.GetAttributeValue('httpResponseStatus') | Should -Be 302
        $settings.GetAttributeValue('exactDestination') | Should -BeFalse
        $settings.GetAttributeValue('childOnly') | Should -BeFalse
    }

    It 'should set redirect on path' {
        'NewWebsite' | Set-Content -Path (Join-Path -Path $script:testWebRoot -ChildPath 'NewWebsite.html')

        Set-CIisHttpRedirect -SiteName $script:siteName -VirtualPath 'SubFolder' -Destination 'http://www.example.com'
        Assert-Redirects -Path 'Subfolder'
        $content = Read-Url -Path 'NewWebsite.html'
        ($content -match 'NewWebsite') | Should -BeTrue

        $settings = Get-CIisHttpRedirect -SiteName $script:siteName -Path 'SubFolder'
        $settings.GetAttributeValue('enabled') | Should -BeTrue
        $settings.GetAttributeValue('destination') | Should -Be 'http://www.example.com'
    }
}
