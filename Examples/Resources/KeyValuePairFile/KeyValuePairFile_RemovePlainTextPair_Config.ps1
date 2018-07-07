#Requires -module FileContentDsc

<#
    .DESCRIPTION
    Remove all `Core.Logging` keys in the file `c:\myapp\myapp.conf`.
#>
Configuration Example
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        KeyValuePairFile RemoveCoreLogging
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Logging'
            Ensure = 'Absent'
        }
    }
}
