#Requires -module FileContentDsc

<#
    .DESCRIPTION
    Set all `Core.Logging` keys to `Information` or add it
    if it is missing in the file `c:\myapp\myapp.conf`.
#>
Configuration Example
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        KeyValuePairFile SetCoreLogging
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Logging'
            Ensure = 'Present'
            Text   = 'Information'
        }
    }
}
