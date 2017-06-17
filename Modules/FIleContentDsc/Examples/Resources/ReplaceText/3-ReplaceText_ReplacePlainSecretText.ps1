<#
    .EXAMPLE
    Set all occrurances of the string '%secret%' to be the value in
    the password set in the parameter $Secret PSCredential object
    in the file 'c:\inetpub\wwwroot\default.htm'.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $Secret
    )

    Import-DSCResource -ModuleName FileContentDsc

    Node $NodeName
    {
        ReplaceText SetSecretText
        {
                Path     = 'c:\inetpub\wwwroot\default.htm'
                Search   = '%secret%'
                Type     = 'Secret'
                Secret   = $Secret

        }
    }
 }
