
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
    `AsDefaults` switch.

    If you want to ensure that any settings that may have gotten changed by hand are reset to their default values, use
    the `-Reset` switch. When set, the `-Reset` switch will reset each setting not passed as an argument to its default
    value.

    .LINK
    %DOCUMENTATION_URL%

    .EXAMPLE
    %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% 'ExampleTwo' %EXAMPLE_ARGUMENTS%

    Demonstrates how to configure an IIS %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION% settings.

    .EXAMPLE
    %CMD_NAME% -%CMD_NAME_PARAMETER_NAME% 'ExampleOne' %EXAMPLE_ARGUMENTS% -Reset

    Demonstrates how to set *all* an IIS %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION% settings by using the
    `-Reset` switch. In this example, the %EXAMPLE_ARGUMENTS% settings are set to custom values, and all other settings
    are deleted, which resets them to their default values.

    .EXAMPLE
    %CMD_NAME% -AsDefaults %EXAMPLE_ARGUMENTS%

    Demonstrates how to configure the IIS %TARGET_OBJECT_TYPE% defaults %TARGET_PROPERTY_DESCRIPTION% settings by using
    the `AsDefaults` switch and not passing the %TARGET_OBJECT_TYPE% name.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(DefaultParameterSetName='SetInstance', SupportsShouldProcess)]
    param(
        # The name of the %TARGET_OBJECT_TYPE% whose %TARGET_PROPERTY_DESCRIPTION% settings to configure.
        [Parameter(Mandatory, ParameterSetName='SetInstance', Position=0)]
        [String] $%CMD_NAME_PARAMETER_NAME%,

        # If true, the function configures the IIS default %TARGET_OBJECT_TYPE% instead of a specific %TARGET_OBJECT_TYPE%.
        [Parameter(Mandatory, ParameterSetName='SetDefaults')]
        [switch] $AsDefaults,

        %CMD_PARAMETERS%,

        # Resets *all* the %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION% settings to their default values,
        # *except* each setting whose cooresponding parameter is passed. The default behavior is to only modify each
        # setting whose corresponding parameter is passed.
        [switch] $Reset
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $target = %GET_CMD_NAME% -Name $%CMD_NAME_PARAMETER_NAME% -Defaults:$AsDefaults
    if( -not $target )
    {
        return
    }

    $targetMsg = 'IIS %TARGET_OBJECT_TYPE defaults'
    if( $%CMD_NAME_PARAMETER_NAME% )
    {
        $targetMsg = """$($%CMD_NAME_PARAMETER_NAME%)"" IIS %TARGET_OBJECT_TYPE%'s %TARGET_PROPERTY_DESCRIPTION%"
    }

    Invoke-SetConfigurationAttribute -ConfigurationElement $target.%PROPERTY_NAME% `
                                     -PSCmdlet $PSCmdlet `
                                     -Target $targetMsg `
                                     -Reset:$Reset
}
