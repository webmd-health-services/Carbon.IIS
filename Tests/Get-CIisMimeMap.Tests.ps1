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
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
}

Describe 'Get-CIisMimeMap' {
    It 'should get all mime types' {
        $mimeMap = Get-CIisMimeMap
        $mimeMap | Should -Not -BeNullOrEmpty
        $mimeMap.Length | Should -BeGreaterThan 0

        $mimeMap.FileExtension | Should -BeLike '.*'
        $mimeMap.MimeType | Should -BeLike '*/*'
    }

    It 'should get wildcard file extension' {
        $mimeMap = Get-CIisMimeMap -FileExtension '.htm*'
        $mimeMap | Should -Not -BeNullOrEmpty
        $mimeMap | Should -HaveCount 2
        $mimeMap[0].FileExtension | Should -Be '.htm'
        $mimeMap[0].MimeType | Should -Be 'text/html'
        $mimeMap[1].FileExtension | Should -Be '.html'
        $mimeMap[1].MimeType | Should -Be 'text/html'
    }


    It 'should get wildcard mime type' {
        $mimeMap = Get-CIisMimeMap -MimeType 'text/*'
        $mimeMap | Should -Not -BeNullOrEmpty
        $mimeMap.Count | Should -BeGreaterThan 1
        $mimeMap.MimeType | Should -BeLike 'text/*'
    }
}
