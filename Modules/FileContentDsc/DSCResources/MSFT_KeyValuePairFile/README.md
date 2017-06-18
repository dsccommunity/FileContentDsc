# Description

The KeyValuePairFile resource is used to add, remove or set key/value pairs
in a text file containing key/value pair entries.

This resource is intended to be used to set key/value pair values in
configuration or data files where no partitions or headings are used to
separate entries and each line contains only a single entry.

This resource should not be used to configure INI files.
The [IniSettingFile](IniSettingFile.md) resource should be used instead.
