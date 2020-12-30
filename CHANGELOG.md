# Change log for FileContentDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Transferred ownership to DSCCommunity.org -
  fixes [Issue #31](https://github.com/dsccommunity/FileContentDsc/issues/39).
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- Updated to use continuous delivery pattern using Azure DevOps - fixes
  [Issue #41](https://github.com/dsccommunity/FileContentDsc/issues/41).
- Updated build badges in README.MD.
- Change Azure DevOps Pipeline definition to include `source/*` - Fixes [Issue #45](https://github.com/dsccommunity/FileContentDsc/issues/45).
- Updated pipeline to use `latest` version of `ModuleBuilder` - Fixes [Issue #45](https://github.com/dsccommunity/FileContentDsc/issues/45).
- Merge `HISTORIC_CHANGELOG.md` into `CHANGELOG.md` - Fixes [Issue #46](https://github.com/dsccommunity/FileContentDsc/issues/46).
- Fixed build failures caused by changes in `ModuleBuilder` module v1.7.0
  by changing `CopyDirectories` to `CopyPaths` - Fixes [Issue #49](https://github.com/dsccommunity/FileContentDsc/issues/49).
- Updated to use the common module _DscResource.Common_ - Fixes [Issue #48](https://github.com/dsccommunity/FileContentDsc/issues/48).
- Pin `Pester` module to 4.10.1 because Pester 5.0 is missing code
  coverage - Fixes [Issue #50](https://github.com/dsccommunity/FileContentDsc/issues/50).
- Automatically publish documentation to GitHub Wiki - Fixes [Issue #51](https://github.com/dsccommunity/FileContentDsc/issues/51).
- Renamed `master` branch to `main` - Fixes [Issue #53](https://github.com/dsccommunity/FileContentDsc/issues/53).

## [1.3.0.151] - 2019-07-20

### Changed

- Opted into Common Tests 'Common Tests - Validate Localization' -
  fixes [Issue #31](https://github.com/PlagueHO/FileContentDsc/issues/32).
- Combined all `FileContent.ResourceHelper` module functions into
  `FileContent.Common` module - fixes [Issue #32](https://github.com/PlagueHO/FileContentDsc/issues/32).
- Renamed all localization strings so that they are detected by
  'Common Tests - Validate Localization'.
- Correct style violations in unit tests:
  - Adding `Get`, `Set` and `Test` tags to appropriate `describe` blocks.
  - Removing uneccesary `#region` blocks.
  - Conversion of double quotes to single quotes where possible.
  - Replace variables with string litterals in `describe` block description.
- KeyValuePairFile:
  - Improve unit tests to simplify and cover additional test cases.
  - Fix error occuring when file is empty or does not exist - fixes [Issue #34](https://github.com/PlagueHO/FileContentDsc/issues/34).

## [1.2.0.138] - 2018-10-27

### Changed

- Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #25](https://github.com/PlagueHO/FileContentDsc/issues/25).
- Added an Encoding parameter to the KeyValuePairFile and ReplaceText
  resources - fixes [Issue #5](https://github.com/PlagueHO/FileContentDsc/issues/5).

## [1.1.0.108] - 2018-10-02

### Changed

- Enabled PSSA rule violations to fail build - Fixes [Issue #6](https://github.com/PlagueHO/FileContentDsc/issues/6).
- Updated tests to meet Pester v4 standard.
- Added Open Code of Conduct.
- Refactored module folder structure to move resource
  to root folder of repository and remove test harness - Fixes [Issue #11](https://github.com/PlagueHO/FileContentDsc/issues/11).
- Converted Examples to support format for publishing to PowerShell
  Gallery.
- Refactor Test-TargetResource to return $false in all DSC resource - Fixes
  [Issue #12](https://github.com/PlagueHO/FileContentDsc/issues/13).
- Correct configuration names in Examples - fixes [Issue #15](https://github.com/PowerShell/FileContentDsc/issues/15).
- Refactor Test/Set-TargetResource in ReplaceText to be able to add a key if it
  doesn't exist but should -Fixes
  [Issue#20](https://github.com/PlagueHO/FileContentDsc/issues/20).
- Opted into common tests:
  - Common Tests - Validate Example Files To Be Published
  - Common Tests - Validate Markdown Links
  - Common Tests - Relative Path Length
  - Common Tests - Relative Path Length
- Correct test context description in IniSettingsFile tests to include 'When'.
- Change IniSettingsFile unit tests to be non-destructive - fixes [Issue #22](https://github.com/PowerShell/FileContentDsc/issues/22).
- Update to new format LICENSE.

## [1.0.0.38] - 2017-09-02

### Changed

- DSR_ReplaceText:
  - Created new resource for replacing text in text files.
- DSR_KeyValuePairFile:
  - Created new resource for setting key value pairs in text files.
- DSR_IniSettingsFile:
  - Created new resource for setting Windows INI file settings.
