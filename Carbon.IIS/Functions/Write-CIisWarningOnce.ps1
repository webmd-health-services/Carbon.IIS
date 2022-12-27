
function Write-CIisWarningOnce
{
    [CmdletBinding(DefaultParameterSetName='Message')]
    param(
        [Parameter(ValueFromPipeline, ParameterSetName='Message')]
        [String] $Message,

        [Parameter(Mandatory, ParameterSetName='ObsoleteSiteNameAndVirtualPath')]
        [switch] $ForObsoleteSiteNameAndVirtualPathParameter
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if ($PSCmdlet.ParameterSetName -eq 'ObsoleteSiteNameAndVirtualPath')
        {
            $functionName = $PSCmdlet.MyInvocation.MyCommand.Name
            $caller = Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1
            if ($caller.FunctionName -like '*-CIis*')
            {
                $functionName = $caller.FunctionName
            }

            $Message = "The $($functionName) function''s ""SiteName"" and ""VirtualPath"" parameters are obsolete " +
                       'and have been replaced with a single "LocationPath" parameter, which should be the combined ' +
                       'path of the location/object to configure, e.g. ' +
                       "``$($functionName) -LocationPath 'SiteName/Virtual/Path'``. You can also use the " +
                       '`Join-CIisPath` function to combine site names and virtual paths into a single location path ' +
                       "e.g. ``$($functionName) -LocationPath ('SiteName', 'Virtual/Path' | Join-CIisPath)``."
        }

        if ($script:warningMessages.ContainsKey($Message))
        {
            return
        }

        Write-Warning -Message $Message

        $script:warningMessages[$Message] = $true
    }
}