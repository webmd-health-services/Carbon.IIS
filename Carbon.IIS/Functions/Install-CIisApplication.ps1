
function Install-CIisApplication
{
    <#
    .SYNOPSIS
    Creates a new application under a website.

    .DESCRIPTION
    Creates a new application at `VirtualPath` under website `SiteName` running the code found on the file system under
    `PhysicalPath`, i.e. if SiteName is is `example.com`, the application is accessible at `example.com/VirtualPath`.
    If an application already exists at that path, it is removed first.  The application can run under a custom
    application pool using the optional `AppPoolName` parameter.  If no app pool is specified, the application runs
    under the same app pool as the website it runs under.

    Beginning with Carbon 2.0, returns a `Microsoft.Web.Administration.Application` object for the new application if
    one is created or modified.

    Beginning with Carbon 2.0, if no app pool name is given, existing application's are updated to use `DefaultAppPool`.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Install-CIisApplication -SiteName Peanuts -VirtualPath CharlieBrown -PhysicalPath C:\Path\To\CharlieBrown -AppPoolName CharlieBrownPool

    Creates an application at `Peanuts/CharlieBrown` which runs from `Path/To/CharlieBrown`.  The application runs under
    the `CharlieBrownPool`.

    .EXAMPLE
    Install-CIisApplication -SiteName Peanuts -VirtualPath Snoopy -PhysicalPath C:\Path\To\Snoopy

    Create an application at Peanuts/Snoopy, which runs from C:\Path\To\Snoopy.  It uses the same application as the
    Peanuts website.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Application])]
    param(
        # The site where the application should be created.
        [Parameter(Mandatory)]
        [string] $SiteName,

        # The path of the application.
        [Parameter(Mandatory)]
        [string] $VirtualPath,

        # The path to the application.
        [Parameter(Mandatory)]
        [string] $PhysicalPath,

        # The app pool for the application. Default is `DefaultAppPool`.
        [string] $AppPoolName,

        # Returns IIS application object. This switch is new in Carbon 2.0.
        [Switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $SiteName
    if( -not $site )
    {
        return
    }

    $iisAppPath = Join-CIisVirtualPath -Path $SiteName -ChildPath $VirtualPath

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        Write-Verbose ('IIS://{0}: creating physical path {1}' -f $iisAppPath,$PhysicalPath)
        $null = New-Item $PhysicalPath -ItemType Directory
    }

    $apps = $site.GetCollection()

    $VirtualPath = $VirtualPath | ConvertTo-CIisVirtualPath
    $app = Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath
    $modified = $false
    if( -not $app )
    {
        Write-Verbose ('IIS://{0}: creating application' -f $iisAppPath)
        $app =
            $apps.CreateElement('application') |
            Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru
        $app['path'] = $VirtualPath
        $apps.Add( $app ) | Out-Null
        $modified = $true
    }

    if( $app['path'] -ne $VirtualPath )
    {
        $app['path'] = $VirtualPath
        $modified = $true
    }

    if( $AppPoolName -and $app['applicationPool'] -ne $AppPoolName)
    {
        $app['applicationPool'] = $AppPoolName
        $modified = $true
    }

    $vdir = $null
    if( $app | Get-Member 'VirtualDirectories' )
    {
        $vdir = $app.VirtualDirectories | Where-Object 'Path' -EQ '/'
    }

    if( -not $vdir )
    {
        Write-Verbose ('IIS://{0}: creating virtual directory' -f $iisAppPath)
        $vdirs = $app.GetCollection()
        $vdir = $vdirs.CreateElement('virtualDirectory')
        $vdir['path'] = '/'
        $vdirs.Add( $vdir ) | Out-Null
        $modified = $true
    }

    if( $vdir['physicalPath'] -ne $PhysicalPath )
    {
        Write-Verbose ('IIS://{0}: setting physical path {1}' -f $iisAppPath,$PhysicalPath)
        $vdir['physicalPath'] = $PhysicalPath
        $modified = $true
    }

    if( $modified )
    {
        Write-Verbose ('IIS://{0}: committing changes' -f $iisAppPath)
        $app.CommitChanges()
    }

    if( $PassThru )
    {
        return Get-CIisApplication -SiteName $SiteName -VirtualPath $VirtualPath
    }
}