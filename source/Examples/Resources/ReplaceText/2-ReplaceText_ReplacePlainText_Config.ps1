<#PSScriptInfo
.VERSION 1.0.0
.GUID 40050783-8d84-4d71-be0c-a03c8da76133
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
    Set all occrurances of the string `%appname%` to be Awesome App`
    in the file `c:\inetpub\wwwroot\default.htm`.
#>
Configuration ReplaceText_ReplacePlainText_Config
{
    Import-DSCResource -ModuleName FileContentDsc

    Node localhost
    {
        ReplaceText SetText
        {
            Path   = 'c:\inetpub\wwwroot\default.htm'
            Search = '%appname%'
            Type   = 'Text'
            Text   = 'Awesome App'
        }
    }
}
