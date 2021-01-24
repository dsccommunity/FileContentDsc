#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)/$($script:subModuleName).psm1"

Import-Module $script:subModuleFile -Force -ErrorAction Stop
#endregion HEADER

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

InModuleScope $script:subModuleName {
    Describe 'FileContentDsc.Common\Get-TextEolCharacter' {
        $textNoNewLine = 'NoNewLine'
        $textCRLFOnly = "CRLFOnly`r`n"
        $textCROnly = "CROnly`r"
        $textBoth = "CRLFLine`r`nCRLine`r"

        Context 'text with no new line' {
            It 'should return CRLF' {
                Get-TextEolCharacter -Text $textNoNewLine | Should -Be "`r`n"
            }
        }

        Context 'text with CRLF only' {
            It 'should return CRLF' {
                Get-TextEolCharacter -Text $textCRLFOnly | Should -Be "`r`n"
            }
        }

        Context 'text with CR only' {
            It 'should return CR' {
                Get-TextEolCharacter -Text $textCROnly | Should -Be "`r"
            }
        }

        Context 'text with both CR and CRLF' {
            It 'should return CRLF' {
                Get-TextEolCharacter -Text $textBoth | Should -Be "`r`n"
            }
        }
    }

    Describe 'FileContentDsc.Common\Get-FileEncoding' {
        $testTextFile = "$TestDrive\TestFile.txt"
        $testCases = @(
            @{
                encoding = 'ASCII'
                value    = [byte[]](97, 98, 99)
            },
            @{
                encoding = 'BigEndianUnicode'
                value    = [byte[]](254, 255, 0, 97, 0, 98, 0, 99)
            },
            @{
                encoding = 'BigEndianUTF32'
                value    = [byte[]](0, 0, 254, 255, 0, 0, 0, 97, 0, 0, 0, 98, 0, 0, 0, 99)
            },
            @{
                encoding = 'UTF8'
                value    = [byte[]](239, 187, 191, 97, 98, 99)
            },
            @{
                encoding = 'UTF8BOM'
                value    = [byte[]](239, 187, 191, 97, 98, 99)
            },
            @{
                encoding = 'UTF8NoBOM'
                value    = [byte[]](97, 98, 99, 226, 157, 164)
            },
            @{
                encoding = 'UTF32'
                value    = [byte[]](255, 254, 0, 0, 97, 0, 0, 0, 98, 0, 0, 0, 99, 0, 0, 0)
            }
        )

        Context 'When checking file encoding' {
            It "Should return '<Encoding>' for file with '<Encoding>' encoding" -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $Encoding,

                    [Parameter()]
                    [byte[]]
                    $value
                )

                # Create a test file in byte format so that it does not depend on the PowerShell version.
                [SYstem.IO.File]::WriteAllBytes($testTextFile, $value)

                if ($Encoding -eq 'UTF8')
                {
                    Get-FileEncoding -Path $testTextFile | Should -Be 'UTF8BOM'
                }
                else
                {
                    Get-FileEncoding -Path $testTextFile | Should -Be $Encoding
                }
            }
        }
    }

    Describe 'FileContentDsc.Common\Set-TextContent' {
        $testTextFile = "TestDrive:\TestFile.txt"
        $value = [string][char]0x0398 #Non-Ascii character
        $testCases = @(
            @{
                encoding             = 'ASCII'
                expectedValueInBytes = [byte[]](63)
            },
            @{
                encoding             = 'BigEndianUnicode'
                expectedValueInBytes = [byte[]](254, 255, 3, 152)
            },
            @{
                encoding             = 'BigEndianUTF32'
                expectedValueInBytes = [byte[]](0, 0, 254, 255, 0, 0, 3, 152)
            },
            @{
                encoding = 'UTF8'
            },
            @{
                encoding             = 'UTF8BOM'
                expectedValueInBytes = [byte[]](239, 187, 191, 206, 152)
            },
            @{
                encoding             = 'UTF8NoBOM'
                expectedValueInBytes = [byte[]](206, 152)
            },
            @{
                encoding             = 'UTF32'
                expectedValueInBytes = [byte[]](255, 254, 0, 0, 152, 3, 0, 0)
            }
        )

        Context 'When save text file' {
            It "Should create a text file with '<Encoding>' encoding" -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $Encoding,

                    [Parameter()]
                    [byte[]]
                    $ExpectedValueInBytes
                )

                Set-TextContent -Path $testTextFile -Value $value -Encoding $Encoding -Force -NoNewLine

                # PowerShell 6 or later
                if ($PSVersionTable.PSVersion.Major -ge 6)
                {
                    $result = Get-Content -Path $testTextFile -Raw -AsByteStream
                    if ($Encoding -eq 'UTF8')
                    {
                        # In the PowerShell v6+, UTF8 has not BOM by default.
                        $result | Should -Be ([byte[]](206, 152))
                    }
                    else
                    {
                        $result | Should -Be $ExpectedValueInBytes
                    }
                }
                # PowerShell 5.1 or earlier
                else
                {
                    $result = Get-Content -Path $testTextFile -Raw -Encoding Byte
                    if ($Encoding -eq 'UTF8')
                    {
                        # In the PowerShell v5, UTF8 has BOM by default.
                        $result | Should -Be ([byte[]](239, 187, 191, 206, 152))
                    }
                    else
                    {
                        $result | Should -Be $ExpectedValueInBytes
                    }
                }
            }
        }
    }
}
