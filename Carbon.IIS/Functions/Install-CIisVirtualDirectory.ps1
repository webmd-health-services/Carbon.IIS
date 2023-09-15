
function Install-CIisVirtualDirectory
{
    <#
    .SYNOPSIS
    Installs a virtual directory.

    .DESCRIPTION
    The `Install-CIisVirtualDirectory` function creates a virtual directory under website `SiteName` at `VirtualPath`,
    serving files out of `PhysicalPath`.  If a virtual directory at `VirtualPath` already exists, it is updated in
    place.

    .EXAMPLE
    Install-CIisVirtualDirectory -SiteName 'Peanuts' -VirtualPath 'DogHouse' -PhysicalPath C:\Peanuts\Doghouse

    Creates a `/DogHouse` virtual directory, which serves files from the C:\Peanuts\Doghouse directory.  If the Peanuts
    website responds to hostname `peanuts.com`, the virtual directory is accessible at `peanuts.com/DogHouse`.

    .EXAMPLE
    Install-CIisVirtualDirectory -SiteName 'Peanuts' -VirtualPath 'Brown/Snoopy/DogHouse' -PhysicalPath C:\Peanuts\DogHouse

    Creates a DogHouse virtual directory under the `Peanuts` website at `/Brown/Snoopy/DogHouse` serving files out of
    the `C:\Peanuts\DogHouse` directory.  If the Peanuts website responds to hostname `peanuts.com`, the virtual
    directory is accessible at `peanuts.com/Brown/Snoopy/DogHouse`.
    #>
    [CmdletBinding()]
    param(
        # The site where the virtual directory should be created.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The virtual path of the virtual directory to install, i.e. the path in the URL to this directory. If creating
        # under an applicaton, this should be the path in the URL *after* the path in the URL to the application.
        [Parameter(Mandatory)]
        [Alias('Name')]
        [String] $VirtualPath,

        # The path of the application under which the virtual directory should get created. The default is to create
        # the virtual directory under website's root application, `/`.
        [String] $ApplicationPath = '/',

        # The file system path to the virtual directory.
        [Parameter(Mandatory)]
        [Alias('Path')]
        [String] $PhysicalPath,

        # Deletes the virtual directory before installation, if it exists.
        #
        # *Does not* delete custom configuration for the virtual directory, just the virtual directory. If you've
        # customized the location of the virtual directory, those customizations will remain in place.
        #
        # The `Force` switch is new in Carbon 2.0.
        [switch] $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -Name $SiteName
    if( -not $site )
    {
        return
    }

    $ApplicationPath = $ApplicationPath | ConvertTo-CIisVirtualPath

    [Microsoft.Web.Administration.Application] $destinationApp =
        $site.Applications | Where-Object 'Path' -EQ $ApplicationPath
    if( -not $destinationApp )
    {
        Write-Error ("The ""$($SiteName)"" website's ""$($ApplicationPath)"" application does not exist.")
        return
    }

    $appDesc = ''
    if ($destinationApp -and $destinationApp.Path -ne '/')
    {
        $appDesc = " under application ""$($destinationApp.Path)"""
    }

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    $VirtualPath = $VirtualPath | ConvertTo-CIisVirtualPath

    $vPathMsg = Join-CIisPath -Path $ApplicationPath, $VirtualPath

    $vdir = $destinationApp.VirtualDirectories | Where-Object 'Path' -EQ $VirtualPath
    if( $Force -and $vdir )
    {
        Write-IisVerbose $SiteName -VirtualPath $vPathMsg 'REMOVE' '' ''
        $destinationApp.VirtualDirectories.Remove($vdir)
        Save-CIisConfiguration
        $vdir = $null

        $site = Get-CIisWebsite -Name $SiteName
        $destinationApp = $site.Applications | Where-Object 'Path' -EQ '/'
    }

    $desc = "IIS virtual directory ""${VirtualPath}""${appDesc} under site ""${SiteName}"
    $created = $false
    if (-not $vdir)
    {
        [Microsoft.Web.Administration.ConfigurationElementCollection]$vdirs = $destinationApp.GetCollection()
        $vdir = $vdirs.CreateElement('virtualDirectory')
        Write-Information "Creating ${desc}."
        Write-Information "  + physicalPath  ${PhysicalPath}"
        $vdir['path'] = $VirtualPath
        [void]$vdirs.Add( $vdir )
        $created = $true
    }

    $modified = $false
    if ($vdir['physicalPath'] -ne $PhysicalPath)
    {
        $vdir['physicalPath'] = $PhysicalPath
        if (-not $created)
        {
            Write-Information $desc
            Write-Information "    physicalPath  $($vdir['physicalPath']) -> ${PhysicalPath}"
        }
        $modified = $true
    }

    if ($created -or $modified)
    {
        Save-CIIsConfiguration
    }
}

