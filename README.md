# FileContentDsc

FileContentDsc contains DSC resources for manipulating the content of files on the target node.
This is most commonly used to set the content of configuration files.

These resources meet the DSC Resource Kit [High Quality Resource Module (HQRM) guidelines](https://github.com/PowerShell/DscResources/blob/master/HighQualityModuleGuidelines.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing

Please check out the common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* [ReplaceText](#ReplaceText): Uses RegEx to find and replace strings in a text file.

### ReplaceText

This resource uses RegEx to find and replace strings in a text file.
It can replace the items matched with the RegEx with either a string or the password from a ```pscredential``` object.
This resource works on Nano Server.

#### Requirements

None

#### Parameters

* **[String] Path** _(Key)_: The path to the text file to replace the string in.
* **[String] Search** _(Key)_: The RegEx string to use to search the text file.
* **[String] Type** _(Write)_: Specifies the value type to use as the replacement string. { *Text* | Password }. Defaults to Text.
* **[String] Text** _(Write)_: The text to replace the text identifed by the RegEx. Only used when Type is set to 'Text'.
* **[String] Password** _(Write)_: The password to replace the text identified by the RegEx. Only used when Type is set to 'Password'.

#### Read-Only Properties from Get-TargetResource

None

#### Examples

* [Create or modify a group with Members](https://github.com/PowerShell/PSDscResources/blob/master/Examples/Sample_Group_Members.ps1)
* [Create or modify a group with MembersToInclude and/or MembersToExclude](https://github.com/PowerShell/PSDscResources/blob/master/Examples/Sample_Group_Members.ps1)

## Versions

### Unreleased

### 1.0.0.0

* Initial release of FileContentDsc
