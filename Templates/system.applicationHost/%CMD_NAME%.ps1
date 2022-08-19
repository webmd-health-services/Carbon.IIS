
function %CMD_NAME%
{
    <#
    .SYNOPSIS
    Configures an IIS %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION% settings.

    .DESCRIPTION
    The `%CMD_NAME%` function configures an IIS %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION%. Pass the name of
    the %TARGET_OBJECT_TYPE% to the `%CMD_NAME_PARAMETER_NAME%` parameter. Pass the %TARGET_PROPERTY_DESCRIPTION% configuration you want to one
    or more of the %PARAMETER_LIST% parameters. See
    [%DOCUMENTATION_TITLE%](%DOCUMENTATION_URL%)
    for documentation on each setting.

    You can configure the IIS default %TARGET_OBJECT_TYPE% instead of a specific %TARGET_OBJECT_TYPE% by using the
    `Defaults` switch.

    If any parameters are not passed, those settings will be reset to their default values.

    .LINK
    %DOCUMENTATION_URL%

    .EXAMPLE
    %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% 'ExampleOne'

    Demonstrates how to reset an IIS %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION% settings to their default
    values by not passing any arguments.

    .EXAMPLE
    %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% 'ExampleTwo' %EXAMPLE_ARGUMENTS%

    Demonstrates how to configure an IIS %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION% settings.

    .EXAMPLE
    %CMD_NAME% -AsDefaults %EXAMPLE_ARGUMENTS%

    Demonstrates how to configure the IIS default %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION% settings by using
    the `AsDefaults` switch and not passing %TARGET_OBJECT_TYPE% name.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the %TARGET_OBJECT_TYPE% whose %TARGET_PROPERTY_DESCRIPTION% settings to set.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $%CMD_NAME_PARAMETER_NAME%,

        # If true, the function configures the IIS default %TARGET_OBJECT_TYPE% instead of a specific %TARGET_OBJECT_TYPE%.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        %CMD_PARAMETERS%
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $target = %GET_CMD_NAME% -Name $%CMD_NAME_PARAMETER_NAME% -Defaults:$AsDefaults
    if( -not $target )
    {
        return
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target.%PROPERTY_NAME% `
                                     -PSCmdlet $PSCmdlet `
                                     -Target """$($%CMD_NAME_PARAMETER_NAME%)"" IIS website's %TARGET_PROPERTY_DESCRIPTION%"
}
