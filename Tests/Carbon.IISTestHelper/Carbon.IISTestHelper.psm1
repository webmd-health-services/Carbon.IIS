
$script:testNum = 0

function New-TestDirectory
{
    $testDir = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
    New-Item -Path $testDir -ItemType 'Directory' | Out-Null
    Grant-CPermission -Path $TestDrive -Identity 'Everyone' -Permission 'FullControl'
    return $testDir
}

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

Export-ModuleMember -Function '*'