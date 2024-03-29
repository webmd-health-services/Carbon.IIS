
function Set-CIisMimeMap
{
    <#
    .SYNOPSIS
    Creates or sets a file extension to MIME type map for an entire web server.

    .DESCRIPTION
    IIS won't serve static files unless they have an entry in the MIME map.  Use this function to create/update a MIME map entry.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Get-CIisMimeMap

    .LINK
    Remove-CIisMimeMap

    .EXAMPLE
    Set-CIisMimeMap -FileExtension '.m4v' -MimeType 'video/x-m4v'

    Adds a MIME map to all websites so that IIS will serve `.m4v` files as `video/x-m4v`.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ForWebServer')]
    param(
        # The name of the website whose MIME type to set.
        [Parameter(Mandatory, ParameterSetName='ForWebsite', Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Parameter(ParameterSetName='ForWebsite')]
        [String] $VirtualPath = '',

        # The file extension to set.
        [Parameter(Mandatory)]
        [String] $FileExtension,

        # The MIME type to serve the files as.
        [Parameter(Mandatory)]
        [String] $MimeType
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

    $mimeMap = $mimeMapCollection | Where-Object { $_['fileExtension'] -eq $FileExtension }

    if( $mimeMap )
    {
        $action = 'Set'
        $mimeMap['fileExtension'] = $FileExtension
        $mimeMap['mimeType'] = $MimeType
    }
    else
    {
        $action = 'Add'
        $mimeMap = $mimeMapCollection.CreateElement("mimeMap");
        $mimeMap["fileExtension"] = $FileExtension
        $mimeMap["mimeType"] = $MimeType
        [void] $mimeMapCollection.Add($mimeMap)
    }

    Save-CIisConfiguration -Target "IIS MIME Map for $($FileExtension) Files" -Action "$($action) MIME Type"
}

