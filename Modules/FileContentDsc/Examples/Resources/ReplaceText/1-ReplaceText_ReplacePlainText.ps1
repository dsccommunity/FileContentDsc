<#
    .EXAMPLE
    Set all occrurances of the string `%appname%` to be Awesome App`
    in the file `c:\inetpub\wwwroot\default.htm`.
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
        ReplaceText SetText
        {
            Path   = 'c:\inetpub\wwwroot\default.htm'
            Search = '%appname%'
            Type   = 'Text'
            Text   = 'Awesome App'
        }
    }
}
