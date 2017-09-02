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
            IniSettingsFile ReplaceTextIntegrationTest
            {
                Path    = $Node.Path
                Section = $Node.Section
                Key     = $Node.Key
                Text    = $Node.Text
            }
        }
        else
        {
            IniSettingsFile ReplaceTextIntegrationTest
            {
                Path    = $Node.Path
                Section = $Node.Section
                Key     = $Node.Key
                Type    = $Node.Type
                Secret  = $Node.Secret
            }
        }
    }
}
