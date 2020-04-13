# FileContentDsc

[![Build Status](https://dev.azure.com/dsccommunity/FileContentDsc/_apis/build/status/dsccommunity.FileContentDsc?branchName=master)](https://dev.azure.com/dsccommunity/FileContentDsc/_build/latest?definitionId=18&branchName=master)
![Code Coverage](https://img.shields.io/azure-devops/coverage/dsccommunity/FileContentDsc/18/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/FileContentDsc/18/master)](https://dsccommunity.visualstudio.com/FileContentDsc/_test/analytics?definitionId=18&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/FileContentDsc?label=FileContentDsc%20Preview)](https://www.powershellgallery.com/packages/FileContentDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/FileContentDsc?label=FileContentDsc)](https://www.powershellgallery.com/packages/FileContentDsc/)

## Code of Conduct

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

This resource module contains resources for setting the content of files.
Configuration text files are the most common use case for this module.

The **FileContent** module contains the following resources:

- **IniSettingsFile**: Add, set or clear entries in Windows INI settings files.
- **KeyValuePairFile**: Add, remove or set key/value pairs in a text file containing
  key/value pairs, and set file encoding.
- **ReplaceText**: Replaces strings matching a regular expression in a file,
  and sets file encoding.

## Documentation and Examples

For a full list of resources in FileContentDsc and examples on their use, check out
the [FileContentDsc wiki](https://github.com/dsccommunity/FileContentDsc/wiki).
