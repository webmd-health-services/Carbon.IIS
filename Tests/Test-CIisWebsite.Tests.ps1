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
}

Describe 'Test-CIisWebsite' {
    BeforeAll {
        Start-W3ServiceTestFixture
    }

    AfterAll {
        Complete-W3ServiceTestFixture
    }

    BeforeEach {
        $script:testDir = New-TestDirectory
    }

    It 'should not find non existent website' {
        Test-CIisWebsite 'jsdifljsdflkjsdf' | Should -BeFalse
    }

    It 'should find existent website' {
        Install-CIisTestWebsite -Name 'Test Website Exists' -PhysicalPath $script:testDir
        try
        {
            Test-CIisWebsite 'Test Website Exists' | Should -BeTrue
        }
        finally
        {
            Uninstall-CIisWebsite 'Test Website Exists'
        }
    }

}
