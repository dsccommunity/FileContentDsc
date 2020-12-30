<#PSScriptInfo
.VERSION 1.0.0
.GUID 89fa6d5d-c121-4502-8bac-5d3ea66e8e80
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
    Set all `Core.Password` keys to the password provided in the $Secret
    credential object or add it if it is missing in the file `c:\myapp\myapp.conf`.
#>
Configuration KeyValuePairFile_SetSecretTextPair_Config
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
        KeyValuePairFile SetCorePassword
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Password'
            Ensure = 'Present'
            Type   = 'Secret'
            Secret = $Secret
        }
    }
}
