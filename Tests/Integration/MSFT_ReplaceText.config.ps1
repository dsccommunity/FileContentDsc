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

    Import-DscResource -ModuleName 'FileContentDsc'

    ReplaceText ReplaceTextIntegrationTest
    {
        Path     = $Path
        Search   = $Search
        Type     = $Type
        Text     = $Text
        Password = $Password
    }
}
