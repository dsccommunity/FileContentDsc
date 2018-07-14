#Requires -module FileContentDsc

<#
    .DESCRIPTION
    Set all occrurances of the string `%appname%` to be Awesome App`
    in the file `c:\inetpub\wwwroot\default.htm`.
#>
Configuration Example
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
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
