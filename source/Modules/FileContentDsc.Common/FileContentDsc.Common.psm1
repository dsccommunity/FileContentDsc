$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'
Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

# Add the types for reading/writing INI files
Add-Type -TypeDefinition @"
    using System.IO;
    using System.Runtime.InteropServices;
    using System.Text;
    public static class IniFile
    {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool WritePrivateProfileString(string lpAppName,
           string lpKeyName, string lpString, string lpFileName);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        static extern uint GetPrivateProfileString(
           string lpAppName,
           string lpKeyName,
           string lpDefault,
           StringBuilder lpReturnedString,
           uint nSize,
           string lpFileName);
        public static void WriteIniSetting(string filePath, string section, string key, string value)
        {
            string fullPath = Path.GetFullPath(filePath);
            bool result = WritePrivateProfileString(section, key, value, fullPath);
        }
        public static string GetIniSetting(string filePath, string section, string key, string defaultValue)
        {
            string fullPath = Path.GetFullPath(filePath);
            StringBuilder sb = new StringBuilder(500);
            GetPrivateProfileString(section, key, defaultValue, sb, (uint)sb.Capacity, fullPath);
            return sb.ToString();
        }
    }
"@

<#
    .SYNOPSIS
        Determines the EOL characters used in a text string.
        If non EOL characters found at all then CRLF will be
        returned.

    .PARAMETER Text
        The text to determine the EOL from.
#>
function Get-TextEolCharacter
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Text
    )

    $eolChar = "`r`n"

    if (-not $Text.Contains("`r`n") -and $Text.Contains("`r"))
    {
        $eolChar = "`r"
    } # if

    return $eolChar
}

<#
    .SYNOPSIS
        Sets or adds the value of an entry in an INI file.

    .PARAMETER Path
        The path to the INI file to set the value in.

    .PARAMETER Section
        The section to add/set the entry in.

    .PARAMETER Key
        The name of the entry to add/set the value to.

    .PARAMETER Value
        The value to set the entry to.
#>
function Set-IniSettingFileValue
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Section,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Value
    )

    $fullPath = Resolve-Path -Path $Path
    [IniFile]::WriteIniSetting($fullPath, $Section, $Key, $Value)
}

<#
    .SYNOPSIS
        Gets the value of an entry in an INI file.

    .PARAMETER Path
        The path to the INI file to get the entry value from.

    .PARAMETER Section
        The section to get the entry value from.

    .PARAMETER Key
        The name of the entry to get the value from.
#>
function Get-IniSettingFileValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Section,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Key
    )

    $fullPath = Resolve-Path -Path $Path
    return [IniFile]::GetIniSetting($fullPath, $Section, $Key, '')
}

<#
    .SYNOPSIS
        Gets file encoding. Defaults to ASCII.

    .DESCRIPTION
        The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
        Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx

    .EXAMPLE
        Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'}
        This command gets ps1 files in current directory where encoding is not ASCII

    .EXAMPLE
        Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'} | `
            foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
        Same as previous example but fixes encoding using set-content
#>
function Get-FileEncoding
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Path
    )

    # The parameter for reading a file as a byte stream are different between PSv6 and later and earlier.
    $ByteParam = if ($PSVersionTable.PSVersion.Major -ge 6)
    {
        @{
            AsByteStream = $true
        }
    }
    else
    {
        @{
            Encoding = 'byte'
        }
    }

    [System.Byte[]] $byte = Get-Content @ByteParam -ReadCount 4 -TotalCount 4 -Path $Path
    if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf)
    {
        return 'UTF8BOM'
    }
    elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe)
    {
        return 'UTF32'
    }
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
    {
        return 'BigEndianUnicode'
    }
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
    {
        return 'BigEndianUTF32'
    }
    else
    {
        # Read all bytes for guessing encoding.
        [System.Byte[]] $byte = Get-Content @ByteParam -ReadCount 0 -Path $Path

        # If a text file includes code after 0x7f, which should not exist in ASCII, it is determined as UTF8NoBOM.
        if ($byte -gt 0x7f)
        {
            return 'UTF8NoBOM'
        }
        else
        {
            return 'ASCII'
        }
    }
}

<#
    .SYNOPSIS
        Writes or replaces the content in an item with new content.
        This is an enhanced version of the Set-Content that allows UTF8BOM and UTF8NoBOM encodings in PS v5.1 and earlier.

    .DESCRIPTION
        Writes or replaces the content in an item with new content.
        This is an enhanced version of the Set-Content that allows UTF8BOM and UTF8NoBOM encodings in PS v5.1 and earlier.

    .EXAMPLE
        Set-TextContent -Path 'C:\hello.txt' -Value 'Hello World' -Encoding UTF8NoBOM
        This command creates a text file encoded in UTF-8 without BOM (Byte Order Mark).
#>
function Set-TextContent
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $Path,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [Object[]]
        $Value,

        [Parameter()]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'BigEndianUTF32', 'UTF8', 'UTF8BOM', 'UTF8NoBOM', 'UTF32')]
        [System.String]
        $Encoding,

        [Parameter()]
        [switch]
        $NoNewLine,

        [Parameter()]
        [switch]
        $Force
    )

    $setContentParams = @{
        Path      = $Path
        Force     = $Force
        NoNewLine = $NoNewLine
    }

    $EncodingParam = $null
    if ($PSBoundParameters.ContainsKey('Encoding'))
    {
        # PS v6+ can handle all Encoding parameters natively
        if ($PSVersionTable.PSVersion.Major -ge 6)
        {
            $EncodingParam = $Encoding
        }
        else
        {
            if ($Encoding -eq 'UTF8BOM')
            {
                $EncodingParam = 'utf8'
            }
            # PS v5.1 and earlier can not handle UTF8 without BOM
            # We need to convert Value to Bytes.
            elseif ($Encoding -eq 'UTF8NoBOM')
            {
                $EncodingParam = 'Byte'
                $Value = [System.Text.Encoding]::UTF8.GetBytes($Value)
            }
            else
            {
                $EncodingParam = $Encoding
            }
        }
    }

    if ($null -ne $EncodingParam)
    {
        $setContentParams.Add('Encoding', $EncodingParam)
    }

    $setContentParams.Add('Value', $Value)

    Set-Content @setContentParams
}

Export-ModuleMember -Function @(
    'Get-TextEolCharacter',
    'Set-IniSettingFileValue',
    'Get-IniSettingFileValue',
    'Get-FileEncoding'
    'Set-TextContent'
)
