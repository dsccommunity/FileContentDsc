[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

$script:dscModuleName = 'FileContentDsc'
$script:dscResourceName = 'DSC_IniSettingsFile'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $script:testTextFile = 'TestFile.ini'
        $script:testText = 'Test Text'
        $script:testSecret = 'Test Secret'
        $script:testSection = 'Section One'
        $script:testKey = 'SettingTwo'
        $script:testTextNoMatch = 'No Match'
        $script:testSecureSecret = ConvertTo-SecureString -String $script:testSecret -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecret)

        Describe 'DSC_IniSettingsFile\Get-TargetResource' -Tag 'Get' {
            Context 'When file exists and entry can be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey)
                    } `
                    -MockWith { $script:testText } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path    | Should -Be $script:testTextFile
                    $script:result.Section | Should -Be $script:testSection
                    $script:result.Key     | Should -Be $script:testKey
                    $script:result.Type    | Should -Be 'Text'
                    $script:result.Text    | Should -Be $script:testText
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey)
                        } `
                        -Exactly 1
                }
            }

            Context 'When file exists and entry can not be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey)
                    } `
                    -MockWith { '' } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path    | Should -Be $script:testTextFile
                    $script:result.Section | Should -Be $script:testSection
                    $script:result.Key     | Should -Be $script:testKey
                    $script:result.Type    | Should -Be 'Text'
                    $script:result.Text    | Should -Be ''
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey)
                        } `
                        -Exactly 1
                }
            }
        }

        Describe 'DSC_IniSettingsFile\Set-TargetResource' -Tag 'Set' {
            Context 'When file exists and text is passed' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $true } `
                    -Verifiable

                Mock -CommandName Out-File

                Mock `
                    -CommandName Set-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey) -and `
                        ($value -eq $script:testText)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Text $script:testText `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled -CommandName Out-File -Exactly 0

                    Assert-MockCalled `
                        -CommandName Set-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey) -and `
                            ($value -eq $script:testText)
                        } `
                        -Exactly 1
                }
            }

            Context 'When file exists and secret is passed' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $true } `
                    -Verifiable

                Mock -CommandName Out-File

                Mock `
                    -CommandName Set-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey) -and `
                        ($value -eq $script:testSecret)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Type 'Secret' `
                            -Secret $script:testSecretCredential `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled -CommandName Out-File -Exactly 0

                    Assert-MockCalled `
                        -CommandName Set-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey) -and `
                            ($value -eq $script:testSecret)
                        } `
                        -Exactly 1
                }
            }

            Context 'When file does not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $false } `
                    -Verifiable

                Mock `
                    -CommandName Out-File `
                    -ParameterFilter {
                        ($FilePath -eq $script:testTextFile)
                    } `
                    -Verifiable

                Mock `
                    -CommandName Set-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey) -and `
                        ($value -eq $script:testText)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Text $script:testText `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter {
                            ($FilePath -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Set-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey) -and `
                            ($value -eq $script:testText)
                        } `
                        -Exactly 1
                }
            }
        }

        Describe 'DSC_ReplaceString\Test-TargetResource' -Tag 'Test' {
            Context 'When file exists and text is passed and matches' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $true } `
                    -Verifiable

                 Mock `
                    -CommandName Get-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey)
                    } `
                    -MockWith { $script:testText } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Text $script:testText `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey)
                        } `
                        -Exactly 1
                }
            }

            Context 'When file exists and text is passed and does not match' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey)
                    } `
                    -MockWith { $script:testTextNoMatch } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Text $script:testText `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey)
                        } `
                        -Exactly 1
                }
            }

            Context 'When file exists and secret text is passed and matches' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey)
                    } `
                    -MockWith { $script:testSecret } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Type 'Secret' `
                            -Secret $script:testSecretCredential `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey)
                        } `
                        -Exactly 1
                }
            }

            Context 'When file exists and text is passed and does not match' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-IniSettingFileValue `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($section -eq $script:testSection) -and `
                        ($key -eq $script:testKey)
                    } `
                    -MockWith { $script:testTextNoMatch } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Type 'Secret' `
                            -Secret $script:testSecretCredential `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-IniSettingFileValue `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($section -eq $script:testSection) -and `
                            ($key -eq $script:testKey)
                        } `
                        -Exactly 1
                }
            }

            Context 'When file does not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter {
                        ($Path -eq $script:testTextFile)
                    } `
                    -MockWith { $false } `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSC_IniSettingsFile' `
                    -MockWith { $false }

                It 'Should return false' {
                    $result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Section $script:testSection `
                        -Key $script:testKey `
                        -Text $script:testText

                    $result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ParameterFilter {
                            ($Path -eq $script:testTextFile)
                        } `
                        -Exactly 1
                }
            }
        }

        Describe 'DSC_IniSettingsFile\Assert-ParametersValid' {
            Context 'When file exists' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Split-Path `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testTextFile } `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $true } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Assert-ParametersValid `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Test-Path -Exactly 1
                }
            }

            Context 'When file parent does not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Split-Path `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testTextFile } `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $false } `
                    -Verifiable

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.FileParentNotFoundError -f $script:testTextFile) `
                    -ArgumentName 'Path'

                It 'Should throw expected exception' {
                    { Assert-ParametersValid `
                            -Path $script:testTextFile `
                            -Section $script:testSection `
                            -Key $script:testKey `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Test-Path -Exactly 1
                }
            }
        }
        #endregion
    }
}
finally
{
    Invoke-TestCleanup
}
