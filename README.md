# FileContentDsc

[![Build status](https://ci.appveyor.com/api/projects/status/b3vo36jocq0tvojw?svg=true)](https://ci.appveyor.com/project/PlagueHO/filecontentdsc)
[![codecov](https://codecov.io/gh/PlagueHO/FileContentDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/PlagueHO/FileContentDsc)

This resource module contains resources for setting the content of files.
Configuration text files are the most common use case for this module.

The **FileContent** module contains the following resources:

- **IniSettingsFile**: Add, set or clear entries in Windows INI settings files.
- **KeyValuePairFile**: Add, remove or set key/value pairs in a text file containing
  key/value pairs.
- **ReplaceText**: Replaces strings matching a regular expression in a file.

**This project is not maintained or supported by Microsoft.**

It has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/).

This module should meet the [PowerShell DSC Resource Kit High Quality Resource
Module Guidelines](https://github.com/PowerShell/DscResources/blob/master/HighQualityModuleGuidelines.md).

## Documentation and Examples

For a full list of resources in FileContentDsc and examples on their use, check out
the [FileContentDsc wiki](https://github.com/PlagueHO/FileContentDsc/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/b3vo36jocq0tvojw/branch/master?svg=true)](https://ci.appveyor.com/project/PlagueHO/filecontentdsc/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/FileContentDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/PlagueHO/FileContentDsc/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/b3vo36jocq0tvojw/branch/dev?svg=true)](https://ci.appveyor.com/project/PlagueHO/filecontentdsc/branch/dev)
[![codecov](https://codecov.io/gh/PlagueHO/FileContentDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/FileContentDsc/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).
