<#
    .EXAMPLE
    Set all occrurances of a string matching the regular expression 
    `<img src=['``"][a-zA-Z0-9.]*['``"]>` with the text `<img src="imgs/placeholder.jpg">`
    in the file `c:\inetpub\wwwroot\default.htm`
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
        ReplaceText SetTextWithRegex
        {
            Path   = 'c:\inetpub\wwwroot\default.htm'
            Search = "<img src=['`"][a-zA-Z0-9.]*['`"]>"
            Type   = 'Text'
            Text   = '<img src="imgs/placeholder.jpg">'
        }
    }
}
