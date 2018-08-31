[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

$script:DSCModuleName   = 'FileContentDsc'
$script:DSCResourceName = 'DSR_ReplaceText'

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
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope 'DSR_ReplaceText' {
        #region Pester Test Initialization
        $script:testTextFile = 'TestFile.txt'
        $script:testText = 'TestText'
        $script:testSecret = 'TestSecret'
        $script:testSearch = "Setting\.Two='(.)*'"
        $script:testSearchNoFind = "Setting.NotExist='(.)*'"
        $script:testTextReplace = "Setting.Two='$($script:testText)'"
        $script:testSecretReplace = "Setting.Two='$($script:testSecret)'"
        $script:testSecureSecretReplace = ConvertTo-SecureString -String $script:testSecretReplace -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecretReplace)

        $script:testFileContent = @"
Setting1=Value1
Setting.Two='Value2'
Setting.Two='Value3'
Setting.Two='$($script:testText)'
Setting3.Test=Value4

"@

        $script:testFileExpectedTextContent = @"
Setting1=Value1
Setting.Two='$($script:testText)'
Setting.Two='$($script:testText)'
Setting.Two='$($script:testText)'
Setting3.Test=Value4

"@

        $script:testFileExpectedSecretContent = @"
Setting1=Value1
Setting.Two='$($script:testSecret)'
Setting.Two='$($script:testSecret)'
Setting.Two='$($script:testSecret)'
Setting3.Test=Value4

"@
        #endregion

        #region Function Get-TargetResource
        Describe 'DSR_ReplaceText\Get-TargetResource' {
            Context 'File exists and search text can be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should -Be $script:testTextFile
                    $script:result.Search | Should -Be $script:testSearch
                    $script:result.Type   | Should -Be 'Text'
                    $script:result.Text   | Should -Be "$($script:testTextReplace),$($script:testTextReplace),$($script:testTextReplace)"
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can not be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearchNoFind `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should -Be $script:testTextFile
                    $script:result.Search | Should -Be $script:testSearchNoFind
                    $script:result.Type   | Should -Be 'Text'
                    $script:result.Text   | Should -BeNullOrEmpty
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'DSR_ReplaceText\Set-TargetResource' {
            Context 'File exists and search text can be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Set-Content `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($value -eq $script:testFileExpectedTextContent)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Text $script:testTextReplace `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Set-Content `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedTextContent)
                        } `
                        -Exactly 1
                }
            }

            Context 'File exists and search secret can be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Set-Content `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($value -eq $script:testFileExpectedSecretContent)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Type 'Secret' `
                        -Secret $script:testSecretCredential `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Set-Content `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedSecretContent)
                        } `
                        -Exactly 1
                }
            }

            Context 'File does not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $null } `
                    -Verifiable

                Mock `
                    -CommandName Set-Content `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($value -eq $script:testTextReplace)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Text $script:testTextReplace `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Set-Content `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testTextReplace)
                        } `
                        -Exactly 1
                }
            }

        }
        #endregion

        #region Function Test-TargetResource
        Describe 'DSR_ReplaceString\Test-TargetResource' {
            Context 'File exists and search text can not be found' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_ReplaceText' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearchNoFind `
                        -Text $script:testTextReplace `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can be found but does not match replace string' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_ReplaceText' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Text $script:testTextReplace `
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
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can be found and matches replace string' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_ReplaceText' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
                        -Text $script:testTextReplace `
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
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can be found but does not match replace secret' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_ReplaceText' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
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
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text can be found and matches replace secret' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_ReplaceText' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedSecretContent } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
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
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and search text cannot be found' {

            }

            Context 'File does not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_ReplaceText' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_ReplaceText' `
                    -MockWith { $false } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent }

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Search $script:testSearchNoFind `
                        -Text $script:testTextReplace `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -Exactly 0
                }
            }
        }
        #endregion

        #region Function Assert-ParametersValid
        Describe 'DSR_ReplaceText\Assert-ParametersValid' {
            Context 'File exists' {
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
                        -Search $script:testSearch `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Test-Path -Exactly 1
                }
            }

            Context 'File parent does not exist' {
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
                    -Message ($localizedData.FileParentNotFoundError -f $script:testTextFile) `
                    -ArgumentName 'Path'

                It 'Should throw expected exception' {
                    { Assert-ParametersValid `
                        -Path $script:testTextFile `
                        -Search $script:testSearch `
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
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
