<#
    .EXAMPLE
    Set the `ConnectionString` entry in the [Database] section to the password
    provided in the $Secret credential object in the file `c:\myapp\myapp.ini`.
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
        IniSettingsFile SetConnectionString
        {
            Path    = 'c:\myapp\myapp.ini'
            Section = 'Database'
            Key     = 'ConnectionString'
            Type    = 'Secret'
            Secret  = $Secret
        }
    }
}
