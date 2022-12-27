
function Install-CIisWebsite
{
    <#
    .SYNOPSIS
    Installs a website.

    .DESCRIPTION
    `Install-CIisWebsite` installs an IIS website. Anonymous authentication is enabled, and the anonymous user is set to
    the website's application pool identity. Before Carbon 2.0, if a website already existed, it was deleted and
    re-created. Beginning with Carbon 2.0, existing websites are modified in place.

    If you don't set the website's app pool, IIS will pick one for you (usually `DefaultAppPool`), an
     `Install-CIisWebsite` will never manage the app pool for you (i.e. if someone changes it manually, this function
     won't set it back to the default). We recommend always supplying an app pool name, even if it is `DefaultAppPool`.

    By default, the site listens on (i.e. is bound to) all IP addresses on port 80 (binding `http/*:80:`). Set custom
    bindings with the `Bindings` argument. Multiple bindings are allowed. Each binding must be in this format (in BNF):

        <PROTOCOL> '/' <IP_ADDRESS> ':' <PORT> ':' [ <HOSTNAME> ]

     * `PROTOCOL` is one of `http` or `https`.
     * `IP_ADDRESS` is a literal IP address, or `*` for all of the computer's IP addresses.  This function does not
     validate if `IPADDRESS` is actually in use on the computer.
     * `PORT` is the port to listen on.
     * `HOSTNAME` is the website's hostname, for name-based hosting.  If no hostname is being used, leave off the
     `HOSTNAME` part.

    Valid bindings are:

     * http/*:80:
     * https/10.2.3.4:443:
     * http/*:80:example.com

     ## Troubleshooting

     In some situations, when you add a website to an application pool that another website/application is part of, the
     new website will fail to load in a browser with a 500 error saying `Failed to map the path '/'.`. We've been unable
     to track down the root cause. The solution is to recycle the app pool, e.g.
     `(Get-CIisAppPool -Name 'AppPoolName').Recycle()`.

    .LINK
    Get-CIisWebsite

    .LINK
    Uninstall-CIisWebsite

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com

    Creates a website named `Peanuts` serving files out of the `C:\Peanuts.com` directory.  The website listens on all
    the computer's IP addresses on port 80.

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -Binding 'http/*:80:peanuts.com'

    Creates a website named `Peanuts` which uses name-based hosting to respond to all requests to any of the machine's
    IP addresses for the `peanuts.com` domain.

    .EXAMPLE
    Install-CIisWebsite -Name 'Peanuts' -PhysicalPath C:\Peanuts.com -AppPoolName 'PeanutsAppPool'

    Creates a website named `Peanuts` that runs under the `PeanutsAppPool` app pool
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        # The name of the website.
        [Parameter(Mandatory, Position=0)]
        [String] $Name,

        # The physical path (i.e. on the file system) to the website. If it doesn't exist, it will be created for you.
        [Parameter(Mandatory, Position=1)]
        [Alias('Path')]
        [String] $PhysicalPath,

        # The site's network bindings.  Default is `http/*:80:`.  Bindings should be specified in
        # `protocol/IPAddress:Port:Hostname` format.
        #
        #  * Protocol should be http or https.
        #  * IPAddress can be a literal IP address or `*`, which means all of the computer's IP addresses.  This
        #  function does not validate if `IPAddress` is actually in use on this computer.
        #  * Leave hostname blank for non-named websites.
        [Parameter(Position=2)]
        [Alias('Bindings')]
        [String[]] $Binding = @('http/*:80:'),

        # The name of the app pool under which the website runs. The app pool must exist. If not provided, IIS picks
        # one for you.  No whammy, no whammy! It is recommended that you create an app pool for each website. That's
        # what the IIS Manager does.
        [String] $AppPoolName,

        # Sets the IIS website's `id` setting.
        [Alias('SiteID')]
        [UInt32] $ID,

        # Sets the IIS website's `serverAutoStart` setting.
        [bool] $ServerAutoStart,

        # Return a `Microsoft.Web.Administration.Site` object for the website.
        [switch] $PassThru,

        [TimeSpan] $Timeout = [TimeSpan]::New(0, 0, 30)
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $bindingRegex = '^(?<Protocol>https?):?//?(?<IPAddress>\*|[\d\.]+):(?<Port>\d+):?(?<HostName>.*)$'

    filter ConvertTo-Binding
    {
        param(
            [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
            [string]
            $InputObject
        )

        Set-StrictMode -Version 'Latest'

        $InputObject -match $bindingRegex | Out-Null
        [pscustomobject]@{
                'Protocol' = $Matches['Protocol'];
                'IPAddress' = $Matches['IPAddress'];
                'Port' = $Matches['Port'];
                'HostName' = $Matches['HostName'];
            } |
            Add-Member -MemberType ScriptProperty `
                       -Name 'BindingInformation' `
                       -Value { '{0}:{1}:{2}' -f $this.IPAddress,$this.Port,$this.HostName } `
                       -PassThru
    }

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        New-Item $PhysicalPath -ItemType Directory | Out-String | Write-Verbose
    }

    $invalidBindings = $Binding | Where-Object { $_ -notmatch $bindingRegex }
    if( $invalidBindings )
    {
        $invalidBindings = $invalidBindings -join "`n`t"
        $errorMsg = 'The following bindings are invalid. The correct format is "protocol/IPAddress:Port:Hostname". ' +
                    'Protocol and IP address must be separted by a single slash, not "://". IP address can be "*" ' +
                    'for all IP addresses. Hostname is optional. If hostname is not provided, the binding must end ' +
                    "with a colon.$([Environment]::NewLine)$($invalidBindings)"
        Write-Error $errorMsg
        return
    }

    [Microsoft.Web.Administration.Site] $site = $null
    $modified = $false
    if( -not (Test-CIisWebsite -Name $Name) )
    {
        $firstBinding = $Binding | Select-Object -First 1 | ConvertTo-Binding
        $mgr = Get-CIisServerManager
        $msg = "Creating IIS website ""$($Name)"" bound to " +
               "$($firstBinding.Protocol)/$($firstBinding.BindingInformation)."
        Write-Information $msg
        $site = $mgr.Sites.Add( $Name, $firstBinding.Protocol, $firstBinding.BindingInformation, $PhysicalPath )
        Save-CIisConfiguration
    }

    $site = Get-CIisWebsite -Name $Name

    $expectedBindings = [Collections.Generic.Hashset[String]]::New()
    $Binding |
        ConvertTo-Binding |
        ForEach-Object { [void]$expectedBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }

    $bindingsToRemove =
        $site.Bindings |
        Where-Object { -not $expectedBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }

    $bindingMsgs = [Collections.Generic.List[String]]::New()

    foreach( $bindingToRemove in $bindingsToRemove )
    {
        $bindingMsgs.Add("- $($bindingToRemove.Protocol)/$($bindingToRemove.BindingInformation)")
        $site.Bindings.Remove( $bindingToRemove )
        $modified = $true
    }

    $existingBindings = [Collections.Generic.Hashset[String]]::New()
    $site.Bindings | ForEach-Object { [void]$existingBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }

    $bindingsToAdd =
        $Binding |
        ConvertTo-Binding |
        Where-Object { -not $existingBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }

    foreach( $bindingToAdd in $bindingsToAdd )
    {
        $bindingMsgs.Add("+ $($bindingToAdd.Protocol)/$($bindingToAdd.BindingInformation)")
        $site.Bindings.Add( $bindingToAdd.BindingInformation, $bindingToAdd.Protocol ) | Out-Null
        $modified = $true
    }

    $prefix = "Configuring ""$($Name)"" IIS website's bindings:  "
    foreach( $bindingMsg in $bindingMsgs )
    {
        Write-Information "$($prefix)$($bindingMsg)"
        $prefix = ' ' * $prefix.Length
    }

    [Microsoft.Web.Administration.Application] $rootApp = $null
    if( $site.Applications.Count -eq 0 )
    {
        Write-Information "Adding ""$($Name)"" IIS website's default application."
        $rootApp = $site.Applications.Add('/', $PhysicalPath)
        $modified = $true
    }
    else
    {
        $rootApp = $site.Applications | Where-Object 'Path' -EQ '/'
    }

    if( $site.PhysicalPath -ne $PhysicalPath )
    {
        Write-Information "Setting ""$($Name)"" IIS website's physical path to ""$($PhysicalPath)""."
        [Microsoft.Web.Administration.VirtualDirectory] $vdir =
            $rootApp.VirtualDirectories | Where-Object 'Path' -EQ '/'
        $vdir.PhysicalPath = $PhysicalPath
        $modified = $true
    }

    if( $AppPoolName )
    {
        if( $rootApp.ApplicationPoolName -ne $AppPoolName )
        {
            Write-Information "Setting ""$($Name)"" IIS website's application pool to ""$($AppPoolName)""."
            $rootApp.ApplicationPoolName = $AppPoolName
            $modified = $true
        }
    }

    if( $modified )
    {
        Save-CIisConfiguration
    }

    $site = Get-CIisWebsite -Name $Name
    # Can't ever remove a site ID, only change it, so set the ID to the website's current value.
    $setArgs = @{
        'ID' = $site.ID;
    }
    foreach( $parameterName in (Get-Command -Name 'Set-CIisWebsite').Parameters.Keys )
    {
        if( -not $PSBoundParameters.ContainsKey($parameterName) )
        {
            continue
        }
        $setArgs[$parameterName] = $PSBoundParameters[$parameterName]
    }
    Set-CIisWebsite @setArgs -Reset

    # Now, wait until site is actually running. Do *not* use Start-CIisWebsite. If there are any HTTPS bindings that
    # don't have an assigned HTTPS certificate the start will fail.
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $website = $null
    do
    {
        $website = Get-CIisWebsite -Name $Name
        if($website.State -ne 'Unknown')
        {
            break
        }

        Start-Sleep -Milliseconds 100
    }
    while ($timer.Elapsed -lt $Timeout)

    if( $PassThru )
    {
        return $website
    }
}

