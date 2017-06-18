<#
    .EXAMPLE
    Set the `Level` entry in the [Logging] section to `Information`
    in the file `c:\myapp\myapp.ini`.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName FileContentDsc

    Node $NodeName
    {
        IniSettingsFile SetLogging
        {
            Path    = 'c:\myapp\myapp.ini'
            Section = 'Logging'
            Key     = 'Level'
            Text    = 'Information'
        }
    }
}
