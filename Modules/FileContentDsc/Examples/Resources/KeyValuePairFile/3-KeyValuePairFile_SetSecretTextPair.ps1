<#
    .EXAMPLE
    Set all `Core.Password` keys to the password provided in the $Secret
    credential object or add it if it is missing in the file `c:\inetpub\wwwroot\default.htm`.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $Secret
    )

    Import-DSCResource -ModuleName FileContentDsc

    Node $NodeName
    {
        KeyValuePairFile SetCoreLogging
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Password'
            Ensure = 'Present'
            Type   = 'Secret'
            Secret = $Secret
        }
    }
}
