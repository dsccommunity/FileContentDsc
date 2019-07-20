$script:ModuleName = 'FileContentDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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
    InModuleScope $script:ModuleName {
        Describe 'NetworkingDsc.Common\Test-IsNanoServer' {
            Context 'When the cmdlet Get-ComputerInfo does not exist' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $false
                    }
                }

                Test-IsNanoServer | Should -Be $false
            }

            Context 'When the current computer is a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo -MockWith {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'NanoServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -Be $true
            }

            Context 'When the current computer is not a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo -MockWith {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'FullServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -Be $false
            }
        }

        Describe 'NetworkingDsc.Common\Get-LocalizedData' {
            $mockTestPath = {
                return $mockTestPathReturnValue
            }

            $mockImportLocalizedData = {
                $BaseDirectory | Should -Be $mockExpectedLanguagePath
            }

            BeforeEach {
                Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
                Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
            }

            Context 'When loading localized data for Swedish' {
                $mockExpectedLanguagePath = 'sv-SE'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with sv-SE language' {
                    Mock -CommandName Join-Path -MockWith {
                        return 'sv-SE'
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 3 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $false

                It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                    Mock -CommandName Join-Path -MockWith {
                        return $ChildPath
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 4 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                Context 'When $ScriptRoot is set to a path' {
                    $mockExpectedLanguagePath = 'sv-SE'
                    $mockTestPathReturnValue = $true

                    It 'Should call Import-LocalizedData with sv-SE language' {
                        Mock -CommandName Join-Path -MockWith {
                            return 'sv-SE'
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }

                    $mockExpectedLanguagePath = 'en-US'
                    $mockTestPathReturnValue = $false

                    It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                        Mock -CommandName Join-Path -MockWith {
                            return $ChildPath
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When loading localized data for English' {
                Mock -CommandName Join-Path -MockWith {
                    return 'en-US'
                } -Verifiable

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with en-US language' {
                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidResultException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-InvalidResultException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-InvalidResultException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-ObjectNotFoundException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-ObjectNotFoundException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-ObjectNotFoundException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidOperationException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-InvalidOperationException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-InvalidOperationException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.InvalidOperationException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-NotImplementedException' {
            Context 'When called with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-NotImplementedException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When called with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-NotImplementedException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.NotImplementedException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidArgumentException' {
            Context 'When calling with both the Message and ArgumentName parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockArgumentName = 'MockArgument'

                    { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } | Should -Throw ('Parameter name: {0}' -f $mockArgumentName)
                }
            }

            Assert-VerifiableMock
        }

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
            $encoding = @(
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
                It "encoding is <encoding> and should return <encoding>" -TestCases $encoding {
                    param($encoding)
                    Set-Content $testTextFile -Value $value -Encoding $encoding
                    Get-FileEncoding -Path $testTextFile | Should -Be $encoding
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    #endregion
}
