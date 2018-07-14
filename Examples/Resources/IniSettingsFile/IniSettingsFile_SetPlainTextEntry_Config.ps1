#Requires -module FileContentDsc

<#
    .DESCRIPTION
    Set the `Level` entry in the [Logging] section to `Information`
    in the file `c:\myapp\myapp.ini`.
#>
Configuration Example
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
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
