
function Copy-Hashtable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Collections.IDictionary] $InputObject,

        [String[]] $Key
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if( -not $Key )
        {
            return $InputObject.Clone()
        }

        $newHashtable = @{}

        foreach( $keyItem in $Key )
        {
            if( -not $InputObject.ContainsKey($keyItem) )
            {
                continue
            }

            $newHashtable[$keyItem] = $InputObject[$keyItem]
        }

        return $newHashtable
    }
}
