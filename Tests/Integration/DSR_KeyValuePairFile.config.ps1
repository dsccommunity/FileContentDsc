param
(
    [Parameter(Mandatory = $true)]
    [System.String]
    $ConfigurationName
)

Configuration $ConfigurationName
{
    Import-DscResource -ModuleName FileContentDsc

    Node localhost {
        if ($Node.Ensure -eq 'Absent')
        {
            KeyValuePairFile KeyValuePairFileIntegrationTest
            {
                Path    = $Node.Path
                Name    = $Node.Name
                Ensure  = $Node.Ensure
            }
        }
        elseif ($Node.Type -eq 'Text')
        {
            KeyValuePairFile KeyValuePairFileIntegrationTest
            {
                Path    = $Node.Path
                Name    = $Node.Name
                Ensure  = $Node.Ensure
                Type    = $Node.Type
                Text    = $Node.Text
            }
        }
        elseif (($Node.Type -eq 'Text') -and ($Node.Encoding -eq 'ASCII'))
        {
            KeyValuePairFile KeyValuePairFileIntegrationTest
            {
                Path     = $Node.Path
                Name     = $Node.Name
                Ensure   = $Node.Ensure
                Type     = $Node.Type
                Text     = $Node.Text
                Encoding = $Node.Encoding
            }
        }
        else
        {
            KeyValuePairFile KeyValuePairFileIntegrationTest
            {
                Path    = $Node.Path
                Name    = $Node.Name
                Ensure  = $Node.Ensure
                Type    = $Node.Type
                Secret  = $Node.Secret
            }
        }
    }
}
