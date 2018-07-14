#Requires -module FileContentDsc

<#
    .DESCRIPTION
    Set all occrurances of a string matching the regular expression
    `<img src=['``"][a-zA-Z0-9.]*['``"]>` with the text `<img src="imgs/placeholder.jpg">`
    in the file `c:\inetpub\wwwroot\default.htm`
#>
Configuration Example
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        ReplaceText SetTextWithRegex
        {
            Path   = 'c:\inetpub\wwwroot\default.htm'
            Search = "<img src=['`"][a-zA-Z0-9.]*['`"]>"
            Type   = 'Text'
            Text   = '<img src="imgs/placeholder.jpg">'
        }
    }
}
