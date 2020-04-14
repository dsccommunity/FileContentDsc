<#PSScriptInfo
.VERSION 1.0.0
.GUID 81ab6eb0-3052-46cd-bea5-653e89d38972
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/FileContentDsc/blob/master/LICENSE
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
    Set all `Core.Logging` keys to `Information` or add it
    if it is missing in the file `c:\myapp\myapp.conf`.
#>
Configuration KeyValuePairFile_SetPlainTextPair_Config
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        KeyValuePairFile SetCoreLogging
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Logging'
            Ensure = 'Present'
            Text   = 'Information'
        }
    }
}
