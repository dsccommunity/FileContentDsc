<#
    .EXAMPLE
    Remove all `Core.Logging` keys in the file `c:\inetpub\wwwroot\default.htm`.
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
        KeyValuePairFile RemoveCoreLogging
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Logging'
            Ensure = 'Absent'
        }
    }
}
