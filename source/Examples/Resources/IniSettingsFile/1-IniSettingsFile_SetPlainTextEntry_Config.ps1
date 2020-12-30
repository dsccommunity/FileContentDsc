<#PSScriptInfo
.VERSION 1.0.0
.GUID 389e1516-5961-4b13-b698-62fbfb8c1107
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
    Set the `Level` entry in the [Logging] section to `Information`
    in the file `c:\myapp\myapp.ini`.
#>
Configuration IniSettingsFile_SetPlainTextEntry_Config
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        IniSettingsFile SetLogging
        {
            Path    = 'c:\myapp\myapp.ini'
            Section = 'Logging'
            Key     = 'Level'
            Text    = 'Information'
        }
    }
}
