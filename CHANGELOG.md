# Versions

## Unreleased

- Enabled PSSA rule violations to fail build - Fixes [Issue #6](https://github.com/PlagueHO/FileContentDsc/issues/6).
- Updated tests to meet Pester v4 standard.
- Added Open Code of Conduct.
- Refactored module folder structure to move resource
  to root folder of repository and remove test harness - Fixes [Issue #11](https://github.com/PlagueHO/FileContentDsc/issues/11).
- Converted Examples to support format for publishing to PowerShell
  Gallery.
- Refactor Test-TargetResource to return $false in all DSC resource -Fixes [Issue #12](https://github.com/PlagueHO/FileContentDsc/issues/13)

## 1.0.0.0

- DSR_ReplaceText:
  - Created new resource for replacing text in text files.
- DSR_KeyValuePairFile:
  - Created new resource for setting key value pairs in text files.
- DSR_IniSettingsFile:
  - Created new resource for setting Windows INI file settings.
