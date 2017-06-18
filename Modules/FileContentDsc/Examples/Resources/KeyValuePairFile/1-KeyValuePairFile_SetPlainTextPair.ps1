<#
    .EXAMPLE
    Set all `Core.Logging` keys to `Information` or add it
    if it is missing in the file `c:\inetpub\wwwroot\default.htm`.
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
            Path    = 'c:\myapp\myapp.conf'
            KeyName = 'Core.Logging'
            Ensure  = 'Present'
            Text    = 'Information'
        }
    }
}
