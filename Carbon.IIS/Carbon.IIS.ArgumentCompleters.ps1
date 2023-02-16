

# Get-Command -ModuleName doesn't work inside a module while its being imported.
$carbonIisCmds = Get-ChildItem -Path 'function:' | Where-Object 'ModuleName' -EQ 'Carbon.IIS'
$alwaysExclude = @{
    'Split-CIisLocationPath' = $true;
    'Write-CIisVerbose' = $true;
    'Write-IisVerbose' = $true;
}

function Format-Argument
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $InputObject
    )

    process
    {
        # If it contains any quote characters, enclose in single quotes and escape just the single quotes. This will
        # handle any double quotes, backticks, and spaces.
        if ($_.Contains("'") -or $_.Contains('"'))
        {
            return "'$($_ -replace "'", "''")'"
        }

        # No quotes, but contains spaces, so enclose in single quotes, which will handle the spaces and any backtick
        # characters.
        if ($_.Contains(' '))
        {
            return "'$($_)'"
        }

        # Sweet. Nothing fancy. Return the original string.
        return $_
    }
}

function Register-CIisArgumentCompleter
{
    [CmdletBinding()]
    param(
        [String] $Filter = '*',

        [String[]] $Exclude,

        [Parameter(Mandatory)]
        [String] $ParameterName,

        [String[]] $ExcludeParameterName,

        [Parameter(Mandatory)]
        [String] $Description,

        [Parameter(Mandatory)]
        [scriptblock] $ScriptBlock
    )

    $cmdNames =
        $carbonIisCmds |
        Where-Object 'Name' -Like $Filter |
        Where-Object { -not $alwaysExclude.ContainsKey($_.Name) } |
        Where-Object {
            $cmd = $_

            if (-not $Exclude)
            {
                return $true
            }

            $excludedMatches = $Exclude | Where-Object { $cmd.Name -like $_ }
            if ($excludedMatches)
            {
                return $false
            }

            return $true
        } |
        Where-Object { $_.Parameters.ContainsKey($ParameterName) } |
        Where-Object {
            $cmd = $_
            if (-not $ExcludeParameterName)
            {
                return $true
            }

            foreach ($excludeFilter in $ExcludeParameterName)
            {
                foreach ($paramName in $cmd.Parameters.Keys)
                {
                    if ($paramName -like $excludeFilter)
                    {
                        return $false
                    }
                }
            }

            return $true
        } |
        Select-Object -ExpandProperty 'Name'

    if (-not $cmdNames)
    {
        $msg =  "Found no $($Description) commands matching filter ""$($Filter)"" with a parameter named " +
                "$($ParameterName)."
        Write-Debug $msg
        return
    }

    Write-Debug "Registering $($Description) auto-completer on parameter ""$($ParameterName)"" for functions"
    $cmdNames | ForEach-Object { "  * $($_)" } | Write-Debug

    Register-ArgumentCompleter -CommandName $cmdNames -ParameterName $ParameterName -ScriptBlock $ScriptBlock
}

$appPoolNameCompleter = {
    param(
        [String] $CommandName,
        [String] $ParameterName,
        [String] $WordToComplete,
        $CommandAst,
        [hashtable] $FakeBoundParameters
    )

    Write-Debug "$($WordToComplete)"

    $completions = @()

    Get-CIisAppPool -Name "$($WordToComplete)*" -ErrorAction Ignore |
        Select-Object -ExpandProperty 'Name' |
        Tee-Object -Variable 'completions' |
        Format-Argument |
        Write-Output

    $completions | ForEach-Object { Write-Debug "> $($_)" }
}

Register-CIisArgumentCompleter -Filter '*-CIisAppPool' `
                               -Exclude 'Install-CIisAppPool' `
                               -ParameterName 'Name' `
                               -Description 'application pool name' `
                               -ScriptBlock $appPoolNameCompleter

Register-CIisArgumentCompleter -Filter '*' `
                               -ParameterName 'AppPoolName' `
                               -Description 'application pool name' `
                               -ScriptBlock $appPoolNameCompleter

$websiteNameCompleter = {
    param(
        [String] $CommandName,
        [String] $ParameterName,
        [String] $WordToComplete,
        $CommandAst,
        [hashtable] $FakeBoundParameters
    )

    Write-Debug "$($WordToComplete)"

    $completions = @()

    Get-CIisWebsite -Name "$($WordToComplete)*" -ErrorAction Ignore |
        Select-Object -ExpandProperty 'Name' |
        Tee-Object -Variable 'completions' |
        Format-Argument |
        Write-Output

    $completions | ForEach-Object { Write-Debug "> $($_)" }
}

Register-CIisArgumentCompleter -Filter '*-CIisWebsite' `
                               -Exclude 'Install-CIisWebsite' `
                               -ParameterName 'Name' `
                               -Description 'website name' `
                               -ScriptBlock $websiteNameCompleter

Register-CIisArgumentCompleter -ParameterName 'SiteName' `
                               -ExcludeParameterName 'LocationPath' `
                               -Description 'website name' `
                               -ScriptBlock $websiteNameCompleter

$appCompleter = {
    param(
        [String] $CommandName,
        [String] $ParameterName,
        [String] $WordToComplete,
        $CommandAst,
        [hashtable] $FakeBoundParameters
    )

    if (-not $FakeBoundParameters.ContainsKey('SiteName'))
    {
        return
    }

    if ($WordToComplete -and $WordToComplete.Length -gt 0 -and $WordToComplete[0] -ne '/')
    {
        $WordToComplete = "/$($WordToComplete)"
    }

    $completions = @()

    Get-CIisApplication -LocationPath (Join-CIisPath $FakeBoundParameters['SiteName'], "$($WordToComplete)*") |
        Select-Object -ExpandProperty 'Path' |
        Tee-Object -Variable 'completions' |
        Format-Argument |
        Write-Output

    $completions | ForEach-Object { Write-Debug "> $($_)" }
}

Register-CIisArgumentCompleter -ParameterName 'VirtualPath' `
                               -ExcludeParameterName 'LocationPath' `
                               -Exclude 'Install-*' `
                               -ScriptBlock $appCompleter `
                               -Description 'application virtual path'

$appCompleter = {
    param(
        [String] $CommandName,
        [String] $ParameterName,
        [String] $WordToComplete,
        $CommandAst,
        [hashtable] $FakeBoundParameters
    )

    if (-not $FakeBoundParameters.ContainsKey('SiteName'))
    {
        Write-Debug 'No SiteName'
        return
    }

    if ($WordToComplete -and $WordToComplete.Length -gt 0 -and $WordToComplete[0] -ne '/')
    {
        $WordToComplete = "/$($WordToComplete)"
    }

    $completions = @()

    Get-CIisApplication -SiteName $FakeBoundParameters['SiteName'] |
        Select-Object -ExpandProperty 'Path'
        Tee-Object -Variable 'completions' |
        Format-Argument |
        Write-Output

    $completions | ForEach-Object { Write-Debug "> $($_)" }
}

Register-CIisArgumentCompleter -Description 'virtual directory' `
                               -ParameterName 'VirtualPath' `
                               -ExcludeParameterName 'LocationPath' `
                               -Exclude 'Install-*' `
                               -ScriptBlock $appCompleter


$locationCompleter = {
    param(
        [String] $CommandName,
        [String] $ParameterName,
        [String] $WordToComplete,
        $CommandAst,
        [hashtable] $FakeBoundParameters
    )

    $ErrorActionPreference = 'Continue'

    # Turn off other debug messages in the locater so if we need to we can debug just what's going on in this script
    # block.
    $PSDefaultParameterValues = @{
        'ConvertTo-CIisVirtualPath:Debug' = $false;
        'Join-CIisPath:Debug' = $false;
        'Get-CIisWebsite:Debug' = $false;
    }

    [String] $siteName = ''
    $locationFilter = '*'
    if ($WordToComplete)
    {
        $locationFilter = "$($WordToComplete)*" | ConvertTo-CIisVirtualPath -NoLeadingSlash
        $siteName, $null = $WordToComplete.Split('/', 2)
    }

    Write-Debug ''
    Write-Debug "$($WordToComplete) -> $($locationFilter)"

    $physicalPathsByVirtualPath = @{}

    [String[]] $completions = @()
    & {
            if (-not $siteName -or -not (Test-CIIsWebsite -Name ([wildcardpattern]::Escape($siteName))))
            {
                Write-Debug "Getting website names."
                Get-CIisWebsite -Name "$($siteName)*" |
                    Select-Object -ExpandProperty 'Name' |
                    ConvertTo-CIisVirtualPath -NoLeadingSlash |
                    Format-Argument |
                    Write-Output
                return
            }

            $site = Get-CIisWebsite -Name $siteName
            $siteLocationPath = $site.Name

            foreach ($app in $site.Applications)
            {
                $appLocationPath = $siteLocationPath
                if ($app.Path -ne '/')
                {
                    $appLocationPath = Join-CIisPath -Path $appLocationPath, $app.Path
                }

                foreach ($vdir in $app.VirtualDirectories)
                {
                    $vdirLocationPath = $appLocationPath
                    if ($vdir.Path -ne '/')
                    {
                        $vdirLocationPath = Join-CIisPath -Path $vdirLocationPath, $vdir.Path
                    }

                    $physicalPathsByVirtualPath[$vdirLocationPath] = $vdir.PhysicalPath

                    if ($vdirLocationPath -like $locationFilter)
                    {
                        Write-Debug "    ~ $($vdirLocationPath)"
                        $vdirLocationPath | Write-Output
                    }
                    else
                    {
                        Write-Debug "  ! ~ $($vdirLocationPath)"
                    }
                }
            }

            # In order to discover any physical paths for auto-completion, we need to break the user's input into two
            # parts on every slash, check if the first part is a virtual path, then check if the second part is a
            # physical directory under that virtual path. For example, if we have wwwroot/VDir/Dir, we need to check
            # if `VDir/Dir` exists under the `wwwroot` virtual path's physical path, then check if `Dir` exists under
            # the `wwwroot/VDir` virtual directory.
            $locationPath, $needle = $WordToComplete.Split('/', 2)
            do
            {
                if ($physicalPathsByVirtualPath.ContainsKey($locationPath))
                {
                    $physicalPath = $physicalPathsByVirtualPath[$locationPath]
                    if ($needle)
                    {
                        $physicalPath = Join-Path -Path $physicalPath -ChildPath $needle
                    }
                    if (Test-Path -Path $physicalPath)
                    {
                        foreach ($dir in (Get-ChildItem -Path $physicalPath -Directory))
                        {
                            Join-CIisPath -Path $locationPath, $needle, $dir.Name | Write-Output
                        }
                    }
                }

                if (-not $needle)
                {
                    break
                }

                $rootSegment, $needle = $needle.Split('/', 2)
                $locationPath = Join-CIisPath $locationPath, $rootSegment
            }
            while ($true)
        } |
        Tee-Object -Variable 'completions' |
        Format-Argument |
        Write-Output

    $completions | ForEach-Object { Write-Debug "> $($_)" }
}

Register-CIisArgumentCompleter -Description 'location path' `
                               -ParameterName 'LocationPath' `
                               -ScriptBlock $locationCompleter
