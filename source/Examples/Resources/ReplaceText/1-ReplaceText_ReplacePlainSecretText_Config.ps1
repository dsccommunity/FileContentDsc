<#PSScriptInfo
.VERSION 1.0.0
.GUID 6a6a7523-91c3-4038-b7f1-178b8dd6803d
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/FileContentDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/FileContentDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module FileContentDsc

<#
    .DESCRIPTION
    Set all occrurances of the string `%secret%` to be the value in
    the password set in the parameter $Secret PSCredential object
    in the file `c:\inetpub\wwwroot\default.htm`.
#>
Configuration ReplaceText_ReplacePlainSecretText_Config
{
    param
    (
        [Parameter()]
        [ValidateNotNullorEmpty()]
        [PSCredential]
        $Secret
    )

    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        ReplaceText SetSecretText
        {
            Path   = 'c:\inetpub\wwwroot\default.htm'
            Search = '%secret%'
            Type   = 'Secret'
            Secret = $Secret
        }
    }
}
