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
        $testTextFile = "TestDrive:\TestFile.txt"
        $value = 'testText'
        $testCases = @(
            @{
                encoding = 'ASCII'
            },
            @{
                encoding = 'BigEndianUnicode'
            },
            @{
                encoding = 'BigEndianUTF32'
            },
            @{
                encoding = 'UTF8'
            },
            @{
                encoding = 'UTF32'
            }
        )

        Context 'When checking file encoding' {
            It "Should return '<Encoding>' for file with '<Encoding>' encoding" -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $Encoding
                )

                Set-Content $testTextFile -Value $value -Encoding $Encoding
                Get-FileEncoding -Path $testTextFile | Should -Be $Encoding
            }
        }
    }
}
