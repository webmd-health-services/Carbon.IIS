
function Save-CIisConfiguration
{
    <#
    .SYNOPSIS
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object] $Configuration,

        [scriptblock] $TestScript
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not ($Configuration | Get-Member -Name 'CommitChanges') )
    {
        $msg = "Unable to save configuration on ""$($Configuration)"": the ""CommitChanges"" method does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $applicationHostPath =
        Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'inetsrv\config\applicationHost.config'
    $lastWriteTimeUtc = Get-Item -Path $applicationHostPath | Select-Object -ExpandProperty 'LastWriteTimeUtc'
    Write-Debug "Committing changes to IIS configuration ""$($Configuration)""."
    $Configuration.CommitChanges()
    $tryFor = [TimeSpan]::New(0, 0, 1)
    $startedWaitingAt = [Diagnostics.Stopwatch]::StartNew()
    do
    {
        $appHostInfo = Get-Item -Path $applicationHostPath -ErrorAction Ignore
        if( $appHostInfo -and $lastWriteTimeUtc -lt $appHostInfo.LastWriteTimeUtc )
        {
            Write-Debug "    $($startedWaitingAt.Elapsed.TotalSeconds.ToString('0.000'))s  Changes committed."
            return
        }
        Write-Debug "  ! $($startedWaitingAt.Elapsed.TotalSeconds.ToString('0.000'))s  Waiting."
        Start-Sleep -Milliseconds 100
    }
    while( $startedWaitingAt.Elapsed -lt $tryFor )
    $msg = "Your IIS changes haven't been saved after waiting for $([int]$tryFor.TotalSeconds) seconds. You may need " +
            "to wait a little longer or restart IIS."
    Write-Warning $msg
}