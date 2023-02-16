
function Get-CIisMimeMap
{
    <#
    .SYNOPSIS
    Gets the file extension to MIME type mappings.

    .DESCRIPTION
    IIS won't serve static content unless there is an entry for it in the web server or website's MIME map
    configuration. This function will return all the MIME maps for the current server.  The objects returned have these
    properties:

     * `FileExtension`: the mapping's file extension
     * `MimeType`: the mapping's MIME type

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    Set-CIisMimeMap

    .EXAMPLE
    Get-CIisMimeMap

    Gets all the the file extension to MIME type mappings for the web server.

    .EXAMPLE
    Get-CIisMimeMap -FileExtension .htm*

    Gets all the file extension to MIME type mappings whose file extension matches the `.htm*` wildcard.

    .EXAMPLE
    Get-CIisMimeMap -MimeType 'text/*'

    Gets all the file extension to MIME type mappings whose MIME type matches the `text/*` wildcard.

    .EXAMPLE
    Get-CIisMimeMap -LocationPath 'DeathStar'

    Gets all the file extenstion to MIME type mappings for the `DeathStar` website.

    .EXAMPLE
    Get-CIisMimeMap -LocationPath 'DeathStar/ExhaustPort'

    Gets all the file extension to MIME type mappings for the `DeathStar`'s `ExhausePort` directory.
    #>
    [CmdletBinding(DefaultParameterSetName='ForWebServer')]
    param(
        # The website whose MIME mappings to return.  If not given, returns the web server's MIME map.
        [Parameter(Mandatory, ParameterSetName='ForWebsite', Position=0)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # OBSOLETE. Use the `LocationPath` parameter instead.
        [Parameter(ParameterSetName='ForWebsite')]
        [Alias('Path')]
        [String] $VirtualPath,

        # The name of the file extensions to return. Wildcards accepted.
        [String] $FileExtension = '*',

        # The name of the MIME type(s) to return.  Wildcards accepted.
        [String] $MimeType = '*'
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
    $staticContent.GetCollection() |
        Where-Object { $_['fileExtension'] -like $FileExtension -and $_['mimeType'] -like $MimeType } |
        ForEach-Object {
            $mimeMap = [pscustomobject]@{ FileExtension = $_['fileExtension']; MimeType = $_['mimeType'] }
            $mimeMap.pstypenames.Add('Carbon.Iis.MimeMap')
            $mimeMap | Write-Output
        }
}

