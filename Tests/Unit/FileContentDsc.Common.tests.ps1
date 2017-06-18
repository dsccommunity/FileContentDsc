$script:ModuleName = 'FileContentDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\FileContentDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    $LocalizedData = InModuleScope $script:ModuleName {
        $LocalizedData
    }

        Describe "$($script:ModuleName)\Get-TextEolCharacter" {

            $textNoNewLine = 'NoNewLine'
            $textCRLFOnly = "CRLFOnly`r`n"
            $textCROnly = "CROnly`r"
            $textBoth = "CRLFLine`r`nCRLine`r"

            Context 'text with no new line' {
                It 'should return CRLF' {
                    Get-TextEolCharacter -Text $textNoNewLine | Should Be "`r`n"
                }
            }

            Context 'text with CRLF only' {
                It 'should return CRLF' {
                    Get-TextEolCharacter -Text $textCRLFOnly | Should Be "`r`n"
                }
            }

            Context 'text with CR only' {
                It 'should return CR' {
                    Get-TextEolCharacter -Text $textCROnly | Should Be "`r"
                }
            }

            Context 'text with both CR and CRLF' {
                It 'should return CRLF' {
                    Get-TextEolCharacter -Text $textBoth | Should Be "`r`n"
                }
            }
        }
    #endregion
}
finally
{
    #region FOOTER
    #endregion
}
