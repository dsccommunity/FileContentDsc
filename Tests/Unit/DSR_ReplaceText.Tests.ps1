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
        $script:testTextReplaceNoFind = "Setting.NotExist='$($script:testText)'"
        $script:testTextReplace = "Setting.Two='$($script:testText)'"
        $script:testSecretReplace = "Setting.Two='$($script:testSecret)'"
        $script:testSecureSecretReplace = ConvertTo-SecureString -String $script:testSecretReplace -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecretReplace)

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

        $script:testFileExpectedTextContentNewKey = @"
Setting1=Value1
Setting.Two='Value2'
Setting.Two='Value3'
Setting.Two='$($script:testText)'
Setting3.Test=Value4
Setting.NotExist='$($script:testText)'

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
            Context 'File exists and search text can be found and encoding is in desired state' {
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
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
                    $script:result.Path     | Should -Be $script:testTextFile
                    $script:result.Search   | Should -Be $script:testSearch
                    $script:result.Type     | Should -Be 'Text'
                    $script:result.Text     | Should -Be "$($script:testTextReplace),$($script:testTextReplace),$($script:testTextReplace)"
                    $script:result.Encoding | Should -Be $script:testCompliantEncoding.Encoding
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

            Context 'File exists and search text can be found but encoding is not in desired state' {
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding } `
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

            Context 'File exists and search text can not be found and encoding is in desired state' {
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
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

            Context 'File exists and search text can not be found but encoding is not in desired state' {
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding } `
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
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
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

            Context 'File exists search text can not be found and AllowAppend is TRUE' {
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
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.encoding } `
                    -Verifiable

                Mock `
                    -CommandName Set-Content `
                    -ParameterFilter {
                    ($path -eq $script:testTextFile) -and `
                    ($value -eq $script:testFileExpectedTextContentNewKey)
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Set-TargetResource `
                            -Path $script:testTextFile `
                            -Search $script:testSearchNoFind `
                            -Text $script:testTextReplaceNoFind `
                            -AllowAppend $true `
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
                        ($value -eq $script:testFileExpectedTextContentNewKey)
                    } `
                        -Exactly 1
                }
            }

            Context 'File exists search text can not be found and AllowAppend is FALSE' {
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
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                Mock `
                    -CommandName Set-Content `
                    -ParameterFilter {
                    ($path -eq $script:testTextFile) -and `
                    ($value -eq $script:testFileContent)
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { $script:result = Set-TargetResource `
                            -Path $script:testTextFile `
                            -Search $script:testSearchNoFind `
                            -Text $script:testTextReplaceNoFind `
                            -AllowAppend $false `
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
                        ($value -eq $script:testFileContent)
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
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
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
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.encoding } `
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
            Context 'File exists search text cannot be found and AllowAppend is TRUE' {
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Search $script:testSearchNoFind `
                            -Text $script:testTextReplace `
                            -AllowAppend $true `
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

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1
                }
            }

            Context 'File exists search text cannot be found and AllowAppend is FALSE and encoding is in desired state' {
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Search $script:testSearchNoFind `
                            -Text $script:testTextReplace `
                            -AllowAppend $false `
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

            Context 'File exists search text cannot be found and AllowAppend is FALSE and encoding is not in desired state' {
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
                    -MockWith { $script:testNonCompliantEncoding.Encoding } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Search $script:testSearchNoFind `
                            -Text $script:testTextReplace `
                            -AllowAppend $false `
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
                        -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly 1

                    Assert-MockCalled `
                        -CommandName Get-FileEncoding `
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
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

                Mock `
                    -CommandName Get-FileEncoding `
                    -ParameterFilter { $path -eq $script:testTextFile } `
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

        Describe 'DSR_ReplaceText\Add-ConfigurationEntry' {
            Context 'Append text' {
                $result = Add-ConfigurationEntry `
                    -Text "Setting.NotExist='$($script:testText)'" `
                    -FileContent $script:testFileContent

                It 'Should append line to end of text' {
                    $result | Should -Be $script:testFileExpectedTextContentNewKey
                }
            }

            Context 'Apply a LF (default *nix)' {
                $nixString = "Line1`nLine2`n"

                $result = Add-ConfigurationEntry `
                    -Text 'Line3' `
                    -FileContent $nixString

                It 'Should end with a LF' {
                    $result -match '\n$'     | Should -BeTrue
                    $result -match '\b\r\n$' | Should -BeFalse
                }
            }

            Context 'Apply a CRLF (default Windows)' {
                $windowsString = "Line1`r`nLine2`r`n"

                $result = Add-ConfigurationEntry `
                    -Text 'Line3' `
                    -FileContent $windowsString

                It 'Should match a CRLF line ending' {
                    $result -match '\r\n$' | Should -BeTrue
                    $result -match '\b\n$' | Should -BeFalse
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
