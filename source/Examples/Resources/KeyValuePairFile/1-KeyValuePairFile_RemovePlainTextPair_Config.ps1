<#PSScriptInfo
.VERSION 1.0.0
.GUID d326f0fb-b169-4602-a508-dbcb07d0e883
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
    Remove all `Core.Logging` keys in the file `c:\myapp\myapp.conf`.
#>
Configuration KeyValuePairFile_RemovePlainTextPair_Config
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        KeyValuePairFile RemoveCoreLogging
        {
            Path   = 'c:\myapp\myapp.conf'
            Name   = 'Core.Logging'
            Ensure = 'Absent'
        }
    }
}
