
function Write-CIisWarningOnce
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [String] $Message
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if ($script:warningMessages.ContainsKey($Message))
        {
            return
        }

        Write-Warning -Message $Message

        $script:warningMessages[$Message] = $true
    }
}