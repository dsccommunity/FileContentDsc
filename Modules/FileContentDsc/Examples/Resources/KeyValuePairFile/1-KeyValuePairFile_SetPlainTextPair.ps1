<#
    .EXAMPLE
    Set all `Core.Logging` keys to `Information` or add it
    if it is missing in the file `c:\myapp\myapp.conf`.
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
        KeyValuePairFile SetCoreLogging
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Logging'
            Ensure = 'Present'
            Text   = 'Information'
        }
    }
}
