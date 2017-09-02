param
(
    [Parameter(Mandatory = $true)]
    [String]
    $ConfigurationName
)

Configuration $ConfigurationName
{
    Import-DscResource -ModuleName FileContentDsc

    Node localhost {
        if ($Node.Type -eq 'Text')
        {
            ReplaceText ReplaceTextIntegrationTest
            {
                Path     = $Node.Path
                Search   = $Node.Search
                Type     = $Node.Type
                Text     = $Node.Text
            }
        }
        else
        {
            ReplaceText ReplaceTextIntegrationTest
            {
                Path     = $Node.Path
                Search   = $Node.Search
                Type     = $Node.Type
                Secret   = $Node.Secret
            }
        }
    }
}
