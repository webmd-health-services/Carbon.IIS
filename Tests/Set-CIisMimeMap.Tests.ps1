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

BeforeAll {
    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

    $script:siteName = 'CarbonSetIisMimeMap'
}

Describe 'Set-CIisMimeMap' {
    BeforeEach {
        Start-W3ServiceTestFixture
        $script:testDir = New-TestDirectory
        Install-CIisWebsite -Name $script:siteName -Binding 'http/*:48284:*' -Path $script:testDir
    }

    AfterEach {
        Uninstall-CIisWebsite -Name $script:siteName
        Complete-W3ServiceTestFixture
    }

    It 'should create new mime map for server' {
        $fileExtension = '.CarbonSetIisMimeMap'
        $mimeType = 'text/plain'

        $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
        $mimeMap | Should -BeNullOrEmpty

        try
        {
            $result = Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType
            $result | Should -BeNullOrEmpty

            $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
            $mimeMap | Should -Not -BeNullOrEmpty
            $fileExtension | Should -Be $mimeMap.FileExtension
            $mimeType | Should -Be $mimeMap.MimeType
        }
        finally
        {
            $result = Remove-CIisMimeMap -FileExtension $fileExtension
            $result | Should -BeNullOrEmpty
        }
    }

    It 'should update existing mime map for server' {
        $fileExtension = '.CarbonSetIisMimeMap'
        $mimeType = 'text/plain'
        $mimeType2 = 'text/html'

        $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
        $mimeMap | Should -BeNullOrEmpty

        try
        {
            Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType
            $result = Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType2
            $result | Should -BeNullOrEmpty

            $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
            $mimeMap | Should -Not -BeNullOrEmpty
            $fileExtension | Should -Be $mimeMap.FileExtension
            $mimeType2 | Should -Be $mimeMap.MimeType
        }
        finally
        {
            Remove-CIisMimeMap -FileExtension $fileExtension
        }
    }

    It 'should support what if' {
        $fileExtension = '.CarbonSetIisMimeMap'
        $mimeType = 'text/plain'

        try
        {
            $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
            $mimeMap | Should -BeNullOrEmpty

            Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType -WhatIf

            $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
            $mimeMap | Should -BeNullOrEmpty
        }
        finally
        {
            Remove-CIisMimeMap -FileExtension $fileExtension
        }
    }

    It 'should add mime map for site' {
        Install-CIisVirtualDirectory -SiteName $script:siteName -VirtualPath '/recurse' -PhysicalPath $PSScriptRoot

        Set-CIisMimeMap -SiteName $script:siteName -FileExtension '.carbon' -MimeType 'carbon/test+site'
        Set-CIisMimeMap -SiteName $script:siteName -VirtualPath '/recurse' -FileExtension '.carbon' -MimeType 'carbon/test+vdir'

        try
        {
            $mime = Get-CIisMimeMap -SiteName $script:siteName -FileExtension '.carbon'
            $mime | Should -Not -BeNullOrEmpty
            $mime.MimeType | Should -Be 'carbon/test+site'

            Remove-CIisMimeMap -SiteName $script:siteName -FileExtension '.carbon'
            $mime = Get-CIisMimeMap -SiteName $script:siteName -FileExtension '.carbon'
            $mime | Should -BeNullOrEmpty

            $mime = Get-CIisMimeMap -SiteName $script:siteName -VirtualPath '/recurse' -FileExtension '.carbon'
            $mime | Should -Not -BeNullOrEmpty
            $mime.MimeType | Should -Be 'carbon/test+vdir'

            Remove-CIisMimeMap -SiteName $script:siteName -VirtualPath '/recurse' -FileExtension '.carbon'
            $mime = Get-CIisMimeMap -SiteName $script:siteName -VirtualPath '/recurse' -FileExtension '.carbon'
            $mime | Should -BeNullOrEmpty
        }
        finally
        {
            Remove-CIisMimeMap -FileExtension '.carbon'
        }
    }
}
