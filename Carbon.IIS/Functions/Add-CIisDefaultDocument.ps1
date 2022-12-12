
function Add-CIisDefaultDocument
{
    <#
    .SYNOPSIS
    Adds a default document name to a website.

    .DESCRIPTION
    If you need a custom default document for your website, this function will add it.  The `FileName` argument should
    be a filename IIS should use for a default document, e.g. home.html.

    If the website already has `FileName` in its list of default documents, this function silently returns.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Add-CIisDefaultDocument -SiteName MySite -FileName home.html

    Adds `home.html` to the list of default documents for the MySite website.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess','')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the site where the default document should be added.
        [Parameter(Mandatory)]
        [Alias('SiteName')]
        [String] $LocationPath,

        # The default document to add.
        [Parameter(Mandatory)]
        [String] $FileName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $section = Get-CIisConfigurationSection -LocationPath $LocationPath -SectionPath 'system.webServer/defaultDocument'
    if( -not $section )
    {
        return
    }

    [Microsoft.Web.Administration.ConfigurationElementCollection] $files = $section.GetCollection('files')
    $defaultDocElement = $files | Where-Object { $_["value"] -eq $FileName }
    if ($defaultDocElement)
    {
        return
    }

    Write-Information "IIS:$($section.LocationPath):$($section.SectionPath)  + $($FileName)"
    $defaultDocElement = $files.CreateElement('add')
    $defaultDocElement["value"] = $FileName
    $files.Add( $defaultDocElement )
    Save-CIisConfiguration
}

