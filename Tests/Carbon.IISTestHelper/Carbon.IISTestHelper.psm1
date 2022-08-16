
Set-StrictMode -Version 'Latest'

$script:testNum = 0

function Complete-W3ServiceTestFixture
{
    if( -not (Test-Path -Path 'env:APPVEYOR') )
    {
        return
    }

    Write-Debug '# Complete-W3ServiceTestFixture'
    Stop-Service -Name 'W3SVC'
    Restart-Service -Name 'WAS'
    Start-Service -Name 'W3SVC'
    Wait-W3Service | Format-Table | Out-String | Write-Debug
}

function New-TestDirectory
{
    $testDir = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
    New-Item -Path $testDir -ItemType 'Directory' | Out-Null
    Grant-CPermission -Path $TestDrive -Identity 'Everyone' -Permission 'FullControl'
    return $testDir
}

function Assert-UrlContent
{
    [CmdletBinding(DefaultParameterSetName='Throws')]
    param(
        [Parameter(Mandatory, Position=0)]
        [Uri] $Url,

        [Parameter(Mandatory, ParameterSetName='Matches')]
        [Alias('Matches')]
        [String] $Match,

        [Parameter(Mandatory, ParameterSetName='Like')]
        [Alias('IsLike')]
        [String] $Like,

        [Parameter(Mandatory, ParameterSetName='Is')]
        [String] $Is
    )

    Write-Debug $Url
    $tryFor = [TimeSpan]::New(0, 0, 1)
    $duration =
        [Diagnostics.Stopwatch]::StartNew() |
        Add-Member -Name 'ToSecondsString' -MemberType ScriptMethod -Value {
            return $this.Elapsed.TotalSeconds.ToString('0.000s')
        } -PassThru

    $content = ''
    $requestOk = $false
    do
    {
        try
        {
            $ProgressPreference = 'SilentlyContinue'
            $response = Invoke-WebRequest -Uri $Url
            $msg = "    $($duration.ToSecondsString())  $($response.StatusCode) $($response.StatusDescription)"
            Write-Debug $msg

            $content = $response.Content

            if( $PSCmdlet.ParameterSetName -eq 'Matches' )
            {
                if( $content -match $Match)
                {
                    Write-Debug "    $($duration.ToSecondsString())  matches /$($Match)/"
                    return
                }
                else
                {
                    Write-Debug "  ! $($duration.ToSecondsString())  matches /$($Match)/"
                }
            }
            elseif( $PSCmdlet.ParameterSetName -eq 'Like' )
            {
                if( $content -Like $Like)
                {
                    Write-Debug "    $($duration.ToSecondsString())  like $($Like)"
                    return
                }
                else
                {
                    Write-Debug "  ! $($duration.ToSecondsString())  like $($Like)"
                }
            }
            elseif( $PSCmdlet.ParameterSetName -eq 'Is' )
            {
                if( $content -eq $Is)
                {
                    Write-Debug "    $($duration.ToSecondsString())  eq $($Is)"
                    return
                }
                else
                {
                    Write-Debug "  ! $($duration.ToSecondsString())  eq $($Is)"
                }
            }
            else
            {
                $requestOk = $true
                break
            }
        }
        catch
        {
            Write-Debug "  ! $($duration.ToSecondsString())  $($_)"
        }

        Start-Sleep -Milliseconds 100
    }
    while( $duration.Elapsed -lt $tryFor )

    if( $PSCmdlet.ParameterSetName -eq 'Matches' )
    {
        $content | Should -Match $Match
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'Like' )
    {
        $content | Should -BeLike $Like
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'Is' )
    {
        $content | Should -Be $Is
    }
    elseif( -not $requestOK )
    {
        Write-Error "Request ""$($Url)"" failed: $($Global:Error[0])." -ErrorAction Stop
    }
}

Set-Alias -Name 'ThenUrlContent' -Value 'Assert-UrlContent'

function Start-W3ServiceTestFixture
{
    if( -not (Test-Path -Path 'env:APPVEYOR') )
    {
        return
    }

    Write-Debug '# Start-W3ServiceTestFixture'
    Start-Service -Name 'WAS'
    Start-Service -Name 'W3SVC'
    Wait-W3Service | Format-Table | Out-String | Write-Debug
}

function ThenAppHostConfig
{
    [CmdletBinding()]
    param(
        [switch] $Not,

        [Parameter(Mandatory, ParameterSetName='ModifiedSince')]
        [DateTime] $ModifiedSince
    )

    $appHostConfigInfo =
        Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config' -Resolve |
        Get-Item

    if( $Not )
    {
        $appHostConfigInfo.LastWriteTime | Should -BeLessOrEqual $ModifiedSince
    }
    else
    {
        $appHostConfigInfo.LastWriteTime | Should -BeGreaterThan $ModifiedSince
    }
}

function ThenError
{
    [CmdletBinding()]
    param(
        [switch] $Not,

        [Parameter(Mandatory, ParameterSetName='Empty')]
        [switch] $Empty,

        [Parameter(Mandatory, ParameterSetName='Is')]
        [String] $Is,

        [Parameter(Mandatory, ParameterSetName='Matches')]
        [Alias('Matches')]
        [String] $Match
    )

    if( $Empty )
    {
        $Global:Error | Should -Not:$Not -BeNullOrEmpty
    }

    if( $Is )
    {
        $Global:Error | Should -Not:$Not -Be $Is
    }

    if( $Match )
    {
        $Global:Error | Should -Not:$Not -Match $Match
    }
}

function Wait-W3Service
{
    foreach( $svcName in @('WAS', 'W3SVC') )
    {
        $timer = [Diagnostics.Stopwatch]::StartNew()
        $tryFor = 5
        do
        {
            $svc = Get-Service -Name $svcName
            $svc | Write-Output
            if( $svc.Status -eq 'Running' )
            {
                break
            }
            Start-Service -Name $svcName
            Start-Sleep -Milliseconds 100
        }
        while( $timer.Elapsed.TotalSeconds -le $tryFor )
    }
}

Export-ModuleMember -Function '*' -Alias '*'