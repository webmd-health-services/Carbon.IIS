
function Test-CIisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Tests if IIS authentication types are enabled or disabled on a site and/or virtual directory under that site.

    .DESCRIPTION
    You can check if anonymous, basic, or Windows authentication are enabled.  There are switches for each authentication type.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Test-CIisSecurityAuthentication -SiteName Peanuts -Anonymous

    Returns `true` if anonymous authentication is enabled for the `Peanuts` site.  `False` if it isn't.

    .EXAMPLE
    Test-CIisSecurityAuthentication -SiteName Peanuts -VirtualPath Doghouse -Basic

    Returns `true` if basic authentication is enabled for`Doghouse` directory under  the `Peanuts` site.  `False` if it isn't.
    #>
    [CmdletBinding()]
    param(
        # The site where anonymous authentication should be set.
        [Parameter(Mandatory)]
        [String] $SiteName,

        # The optional path where anonymous authentication should be set.
        [String] $VirtualPath = '',

        # Tests if anonymous authentication is enabled.
        [Parameter(Mandatory, ParameterSetName='Anonymous')]
        [switch] $Anonymous,

        # Tests if basic authentication is enabled.
        [Parameter(Mandatory, ParameterSetName='Basic')]
        [switch] $Basic,

        # Tests if digest authentication is enabled.
        [Parameter(Mandatory, ParameterSetName='Digest')]
        [switch] $Digest,

        # Tests if Windows authentication is enabled.
        [Parameter(Mandatory, ParameterSetName='Windows')]
        [switch] $Windows
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $getConfigArgs = @{ $pscmdlet.ParameterSetName = $true }
    $authSettings = Get-CIisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getConfigArgs
    return ($authSettings.GetAttributeValue('enabled') -eq 'true')
}

