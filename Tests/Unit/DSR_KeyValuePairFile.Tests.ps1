[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

$script:DSCModuleName   = 'FileContentDsc'
$script:DSCResourceName = 'DSR_KeyValuePairFile'

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
    InModuleScope 'DSR_KeyValuePairFile' {
        #region Pester Test Initialization
        $script:testTextFile = 'TestFile.txt'
        $script:testName = 'Setting.Two'
        $script:testNameNotFound = 'Setting.NotFound'
        $script:testAddedName = 'Setting.Four'
        $script:testText = 'Test Text'
        $script:testSecret = 'Test Secret'
        $script:testSecureSecret = ConvertTo-SecureString -String $script:testSecret -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecret)

        $script:fileEncodingParameters = @{
            Path     =  $script:testTextFile
            Encoding = 'ASCII'
        }

        $script:testCompliantEncoding = @{
            Path     = $script:fileEncodingParameters.Path
            Encoding = $script:fileEncodingParameters.Encoding
        }

        $script:testNonCompliantEncoding = @{
            Path     = $script:fileEncodingParameters.Path
            Encoding = 'UTF8'
        }

        $script:testFileContent = @"
Setting1=Value1
$($script:testName)=Value 2
$($script:testName)=Value 3
$($script:testName)=$($script:testText)
Setting3.Test=Value4

"@

        $script:testFileExpectedTextContent = @"
Setting1=Value1
$($script:testName)=$($script:testText)
$($script:testName)=$($script:testText)
$($script:testName)=$($script:testText)
Setting3.Test=Value4

"@

        $script:testFileExpectedTextContentUpper = @"
Setting1=Value1
$($script:testName.ToUpper())=$($script:testText)
$($script:testName.ToUpper())=$($script:testText)
$($script:testName.ToUpper())=$($script:testText)
Setting3.Test=Value4

"@

        $script:testFileExpectedSecretContent = @"
Setting1=Value1
$($script:testName)=$($script:testSecret)
$($script:testName)=$($script:testSecret)
$($script:testName)=$($script:testSecret)
Setting3.Test=Value4

"@

        $script:testFileExpectedAbsentContent = @"
Setting1=Value1
Setting3.Test=Value4

"@

        $script:testFileExpectedTextContentAdded = @"
Setting1=Value1
$($script:testName)=Value 2
$($script:testName)=Value 3
$($script:testName)=$($script:testText)
Setting3.Test=Value4
$($script:testAddedName)=$($script:testText)

"@

        #endregion

        #region Function Get-TargetResource
        Describe 'DSR_KeyValuePairFile\Get-TargetResource' {
            Context 'File exists and contains matching key and encoding is in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path     | Should -Be $script:testTextFile
                    $script:result.Name     | Should -Be $script:testName
                    $script:result.Ensure   | Should -Be 'Present'
                    $script:result.Type     | Should -Be 'Text'
                    $script:result.Text     | Should -Be "$($script:testText),$($script:testText),$($script:testText)"
                    $script:result.Encoding | Should -Be $script:fileEncodingParameters.Encoding
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and contains matching key but encoding is not in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path     | Should -Be $script:testTextFile
                    $script:result.Name     | Should -Be $script:testName
                    $script:result.Ensure   | Should -Be 'Present'
                    $script:result.Type     | Should -Be 'Text'
                    $script:result.Text     | Should -Be "$($script:testText),$($script:testText),$($script:testText)"
                    $script:result.Encoding | Should -Be $script:testNonCompliantEncoding.Encoding
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and does not contain matching key and encoding is in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path     | Should -Be $script:testTextFile
                    $script:result.Name     | Should -Be $script:testName
                    $script:result.Ensure   | Should -Be 'Absent'
                    $script:result.Type     | Should -Be 'Text'
                    $script:result.Text     | Should -BeNullOrEmpty
                    $script:result.Encoding | Should -Be $script:fileEncodingParameters.Encoding
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and does not contain matching key and encoding is not in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path     | Should -Be $script:testTextFile
                    $script:result.Name     | Should -Be $script:testName
                    $script:result.Ensure   | Should -Be 'Absent'
                    $script:result.Type     | Should -Be 'Text'
                    $script:result.Text     | Should -BeNullOrEmpty
                    $script:result.Encoding | Should -Be $script:testNonCompliantEncoding.Encoding
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'DSR_KeyValuePairFile\Set-TargetResource' {
            Context 'File does not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $null } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $null } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Present' `
                        -Text $script:testText `
                        -Encoding $script:fileEncodingParameters.Encoding `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-ParametersValid -Exactly 1
                }
            }

            Context 'File exists and contains matching key that should exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
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
                        ($value -eq $script:testFileExpectedTextContent) `
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Present' `
                        -Text $script:testText `
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

            Context 'File exists and contains matching key that should exist and contain a secret' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
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
                        -Name $script:testName `
                        -Ensure 'Present' `
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

            Context 'File exists and does not contain matching key but key should exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
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
                        ($value -eq $script:testFileExpectedTextContentAdded)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testAddedName `
                        -Ensure 'Present' `
                        -Text $script:testText `
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
                            ($value -eq $script:testFileExpectedTextContentAdded)
                        } `
                        -Exactly 1
                }
            }

            Context 'File exists and contains key with a different case that should exist and IgnoreNameCase is True' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
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
                        ($value -eq $script:testFileExpectedTextContentUpper)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Ensure 'Present' `
                        -Text $script:testText `
                        -IgnoreNameCase:$true `
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
                            ($value -eq $script:testFileExpectedTextContentUpper)
                        } `
                        -Exactly 1
                }
            }

            Context 'File exists and does not contain key with matching case and should not and encoding is in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                # non-verifiable mocks
                Mock `
                    -CommandName Set-Content

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Encoding $script:fileEncodingParameters.Encoding `
                        -Ensure 'Absent' `
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
                        -Exactly 0

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and does not contain key with matching case and should not but encoding in not in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding
                    } `
                    -Verifiable

                # non-verifiable mocks
                Mock `
                    -CommandName Set-Content

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Encoding $script:fileEncodingParameters.Encoding `
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
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and contains key with a different case but should not and IgnoreNameCase is True' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
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
                        ($value -eq $script:testFileExpectedAbsentContent)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Absent' `
                        -IgnoreNameCase:$true `
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
                            ($value -eq $script:testFileExpectedAbsentContent)
                        } `
                        -Exactly 1
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'DSR_KeyValuePairFile\Test-TargetResource' {
            Context 'File exists and does not contain matching key but it should' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Ensure 'Present' `
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
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and does not contain matching key and should not and encoding is in desired state ' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Ensure 'Absent' `
                        -Encoding $script:fileEncodingParameters.Encoding `
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

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and does not contain matching key and should not but encoding is not in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Ensure 'Absent' `
                        -Encoding $script:fileEncodingParameters.Encoding `
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

                        Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and contains matching key that should exist and values match' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Present' `
                        -Text $script:testText `
                        -Encoding $script:fileEncodingParameters.Encoding `
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

            Context 'File exists and contains matching key that should exist and values do not match secret text' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileContent } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Present' `
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

            Context 'File exists and contains matching key that should exist and values match secret text' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedSecretContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Present' `
                        -Type 'Secret' `
                        -Secret $script:testSecretCredential `
                        -Encoding $script:fileEncodingParameters.Encoding `
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

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and contains matching key that should exist and values match but are different case and IgnoreValueCase is False' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Present' `
                        -Text $script:testText.ToUpper() `
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

            Context 'File exists and contains matching key that should exist and values match but are different case and IgnoreValueCase is True' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Name $script:testName `
                            -Ensure 'Present' `
                            -Text $script:testText.ToUpper() `
                            -Encoding $script:fileEncodingParameters.Encoding `
                            -IgnoreValueCase:$true `
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

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and contains matching key that should not exist' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testFileExpectedTextContent } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Absent' `
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
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists and encoding is not in desired state' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-ParametersValid `
                    -ModuleName 'DSR_KeyValuePairFile' `
                    -Verifiable

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Encoding $script:fileEncodingParameters.Encoding `
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
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }
        }

        #endregion

        #region Function Assert-ParametersValid
        Describe 'DSR_KeyValuePairFile\Assert-ParametersValid' {
            Context 'File parent path exists' {
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
                            -Name $script:testName `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Test-Path -Exactly 1
                }
            }

            Context 'File parent path does not exist' {
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
                            -Name $script:testName `
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
