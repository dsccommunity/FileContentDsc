#Requires -module FileContentDsc

<#
    .DESCRIPTION
    Set all `Core.Password` keys to the password provided in the $Secret
    credential object or add it if it is missing in the file `c:\myapp\myapp.conf`.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $Secret
    )

    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        KeyValuePairFile SetCorePassword
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Password'
            Ensure = 'Present'
            Type   = 'Secret'
            Secret = $Secret
        }
    }
}
