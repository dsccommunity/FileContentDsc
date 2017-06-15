
# Integration Test Config Template Version 1.0.0
param
(
    [Parameter(Mandatory = $true)]
    [String]
    $ConfigurationName
)

Configuration $ConfigurationName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Search,

        [ValidateSet('Text', 'Password')]
        [String]
        $Type = 'Text',

        [ValidateNotNullOrEmpty()]
        [String]
        $Text,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Password
    )

    Import-DscResource -ModuleName FileContentDsc

    Node localhost {
        ReplaceText ReplaceTextIntegrationTest
        {
            Path     = $Path
            Search   = $Search
            Type     = $Type
            Text     = $Text
            Password = $Password
        }
    }
}
