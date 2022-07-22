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

$siteName = 'CarbonSetIisMimeMap'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-CIisWebsite -Name $siteName -Binding 'http/*:48284:*' -Path $TestDir
}

function Stop-Test
{
    Remove-CIisWebsite -Name $siteName
}

function Test-ShouldCreateNewMimeMapForServer
{
    $fileExtension = '.CarbonSetIisMimeMap'
    $mimeType = 'text/plain'
    
    $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
    Assert-Null $mimeMap
    
    try
    {
        $result = Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType
        Assert-Null $result 'objects returned from Set-CIisMimeMap'
        
        $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
        Assert-NotNull $mimeMap
        Assert-Equal $mimeMap.FileExtension $fileExtension
        Assert-Equal $mimeMap.MimeType $mimeType
    }
    finally
    {
        $result = Remove-CIisMimeMap -FileExtension $fileExtension
        Assert-Null $result 'objects returned from Remove-CIisMimeMap'
    }
}

function Test-ShouldUpdateExistingMimeMapForServer
{
    $fileExtension = '.CarbonSetIisMimeMap'
    $mimeType = 'text/plain'
    $mimeType2 = 'text/html'
    
    $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
    Assert-Null $mimeMap
    
    try
    {
        Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType
        $result = Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType2
        Assert-Null $result 'objects returned from Set-CIisMimeMap'
        
        $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
        Assert-NotNull $mimeMap
        Assert-Equal $mimeMap.FileExtension $fileExtension
        Assert-Equal $mimeMap.MimeType $mimeType2
    }
    finally
    {
        Remove-CIisMimeMap -FileExtension $fileExtension
    }
}

function Test-ShouldSupportWhatIf
{
    $fileExtension = '.CarbonSetIisMimeMap'
    $mimeType = 'text/plain'

    try
    {    
        $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
        Assert-Null $mimeMap
        
        Set-CIisMimeMap -FileExtension $fileExtension -MimeType $mimeType -WhatIf
        
        $mimeMap = Get-CIisMimeMap -FileExtension $fileExtension
        Assert-Null $mimeMap
    }
    finally
    {
        Remove-CIisMimeMap -FileExtension $fileExtension
    }    
}

function Test-ShouldAddMimeMapForSite
{
    Install-CIisVirtualDirectory -SiteName $siteName -VirtualPath '/recurse' -PhysicalPath $PSScriptRoot

    Set-CIisMimeMap -SiteName $siteName -FileExtension '.carbon' -MimeType 'carbon/test+site'
    Set-CIisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon' -MimeType 'carbon/test+vdir'

    try
    {
        $mime = Get-CIisMimeMap -SiteName $siteName -FileExtension '.carbon'
        Assert-NotNull $mime
        Assert-Equal 'carbon/test+site' $mime.MimeType

        Remove-CIisMimeMap -SiteName $siteName -FileExtension '.carbon'
        $mime = Get-CIisMimeMap -SiteName $siteName -FileExtension '.carbon'
        Assert-Null $mime

        $mime = Get-CIisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon'
        Assert-NotNull $mime
        Assert-Equal 'carbon/test+vdir' $mime.MimeType

        Remove-CIisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon'
        $mime = Get-CIisMimeMap -SiteName $siteName -VirtualPath '/recurse' -FileExtension '.carbon'
        Assert-Null $mime
    }
    finally
    {
        Remove-CIisMimeMap -FileExtension '.carbon'
    }
}
