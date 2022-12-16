
function Remove-CIisMimeMap
{
    <#
    .SYNOPSIS
    Removes a file extension to MIME type map from an entire web server.

    .DESCRIPTION
    IIS won't serve static files unless they have an entry in the MIME map.  Use this function toremvoe an existing MIME map entry.  If one doesn't exist, nothing happens.  Not even an error.

    If a specific website has the file extension in its MIME map, that site will continue to serve files with those extensions.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Get-CIisMimeMap

    .LINK
    Set-CIisMimeMap

    .EXAMPLE
    Remove-CIisMimeMap -FileExtension '.m4v' -MimeType 'video/x-m4v'

    Removes the `.m4v` file extension so that IIS will no longer serve those files.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ForWebServer')]
    param(
        # The name of the website whose MIME type to set.
        [Parameter(Mandatory, ParameterSetName='ForWebsite', Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Uset the `LocationPath` parameter instead.
        [Parameter(ParameterSetName='ForWebsite')]
        [String] $VirtualPath = '',

        # The file extension whose MIME map to remove.
        [Parameter(Mandatory)]
        [String] $FileExtension
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getIisConfigSectionParams = @{ }
    if( $PSCmdlet.ParameterSetName -eq 'ForWebsite' )
    {
        $getIisConfigSectionParams['LocationPath'] = $LocationPath
        $getIisConfigSectionParams['VirtualPath'] = $VirtualPath
    }

    $staticContent =
        Get-CIisConfigurationSection -SectionPath 'system.webServer/staticContent' @getIisConfigSectionParams
    $mimeMapCollection = $staticContent.GetCollection()
    $mimeMapToRemove = $mimeMapCollection | Where-Object { $_['fileExtension'] -eq $FileExtension }
    if( -not $mimeMapToRemove )
    {
        Write-Verbose ('MIME map for file extension {0} not found.' -f $FileExtension)
        return
    }

    $mimeMapCollection.Remove( $mimeMapToRemove )
    Save-CIisConfiguration
}

