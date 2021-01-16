[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

$script:dscModuleName = 'FileContentDsc'
$script:dscResourceName = 'DSC_KeyValuePairFile'

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
        $script:testTextFile = 'TestFile.txt'
        $script:testName = 'Setting.Two'
        $script:testNameNotFound = 'Setting.NotFound'
        $script:testAddedName = 'Setting.Four'
        $script:testText = 'Test Text'
        $script:testSecret = 'Test Secret'
        $script:testSecureSecret = ConvertTo-SecureString -String $script:testSecret -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecret)

        $script:fileEncodingParameters = @{
            Path     = $script:testTextFile
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

        Describe 'DSC_KeyValuePairFile\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                Mock -CommandName Assert-ParametersValid
            }

            Context 'When the file does not exist' {
                Mock -CommandName Test-Path `
                    -MockWith { $false }

                Mock -CommandName Get-Content
                Mock -CommandName Get-FileEncoding

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should -Be $script:testTextFile
                    $script:result.Name   | Should -Be $script:testName
                    $script:result.Ensure | Should -Be 'Absent'
                    $script:result.Type   | Should -Be 'Text'
                    $script:result.Text   | Should -BeNullOrEmpty
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Test-Path `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -Exactly -Times 0

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -Exactly -Times 0
                }
            }

            Context 'When the file is empty' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content
                Mock -CommandName Get-FileEncoding

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should -Be $script:testTextFile
                    $script:result.Name   | Should -Be $script:testName
                    $script:result.Ensure | Should -Be 'Absent'
                    $script:result.Type   | Should -Be 'Text'
                    $script:result.Text   | Should -BeNullOrEmpty
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Test-Path `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Scope Context `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should -Be $script:testTextFile
                    $script:result.Name   | Should -Be $script:testName
                    $script:result.Ensure | Should -Be 'Present'
                    $script:result.Type   | Should -Be 'Text'
                    $script:result.Text   | Should -Be "$($script:testText),$($script:testText),$($script:testText)"
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Test-Path `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and does not contain a matching key' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                $script:result = $null

                It 'Should not throw an exception' {
                    { $script:result = Get-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected values' {
                    $script:result.Path   | Should -Be $script:testTextFile
                    $script:result.Name   | Should -Be $script:testName
                    $script:result.Ensure | Should -Be 'Absent'
                    $script:result.Type   | Should -Be 'Text'
                    $script:result.Text   | Should -BeNullOrEmpty
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Test-Path `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_KeyValuePairFile\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                Mock -CommandName Assert-ParametersValid
            }

            Context 'When the file does not exist' {
                Mock -CommandName Get-Content

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq "$script:testName=$script:testText")
                        } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file is empty' {
                Mock -CommandName Get-Content

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq "$script:testName=$script:testText")
                        } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist' {
                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedTextContent)
                        } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and contain a secret' {
                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedSecretContent)
                        } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists does not contain a matching key but key should exist' {
                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced `
                    -ParameterFilter {
                        ($path -eq $script:testTextFile) -and `
                        ($value -eq $script:testFileExpectedTextContentAdded)
                    }

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedTextContentAdded)
                        } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a key with a different case that should exist and IgnoreNameCase is True' {
                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedTextContentUpper)
                        } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and does not contain a key with matching case and should not' {
                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -Exactly -Times 0
                }
            }

            Context 'When the file exists and contains a key with a different case but should not and IgnoreNameCase is True' {
                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                Mock -CommandName Set-ContentEnhanced

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-ContentEnhanced `
                        -Scope Context `
                        -ParameterFilter {
                            ($path -eq $script:testTextFile) -and `
                            ($value -eq $script:testFileExpectedAbsentContent)
                        } `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_KeyValuePairFile\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                Mock -CommandName Assert-ParametersValid
            }

            Context 'When the file does not exist but should contain a matching key' {
                Mock -CommandName Test-Path `
                    -MockWith { $false }

                Mock -CommandName Get-Content
                Mock -CommandName Get-FileEncoding

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -Exactly -Times 0

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -Exactly -Times 0
                }
            }

            Context 'When the file does not exist and should not contain a matching key' {
                Mock -CommandName Test-Path `
                    -MockWith { $false }

                Mock -CommandName Get-Content
                Mock -CommandName Get-FileEncoding

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Ensure 'Absent' `
                        -Text $script:testText `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -Exactly -Times 0

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -Exactly -Times 0
                }
            }

            Context 'When the file exists but is empty so does not contain a matching key but it should' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content
                Mock -CommandName Get-FileEncoding

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -Exactly -Times 0
                }
            }

            Context 'When the file exists but is empty so does not contain a matching and should not' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content
                Mock -CommandName Get-FileEncoding

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Ensure 'Absent' `
                        -Text $script:testText `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -Exactly -Times 0
                }
            }

            Context 'When the file exists and does not contain a matching key but it should' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and does not contain a matching key and should not' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and does not contain a matching key and should not but encoding is not in desired state' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testNonCompliantEncoding.Encoding }

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Encoding $script:fileEncodingParameters.Encoding `
                        -Ensure 'Absent' `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and values match' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName `
                        -Ensure 'Present' `
                        -Text $script:testText `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and values match but encoding is not in desired state' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testNonCompliantEncoding.Encoding }

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

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and values do not match secret text' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and values match secret text' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedSecretContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

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

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and values match secret text but encoding is not in desired state' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedSecretContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testNonCompliantEncoding.Encoding }

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

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a key with different case that should exist and values match and IgnoreNameCase is True' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                        -Path $script:testTextFile `
                        -Name $script:testName.ToUpper() `
                        -Ensure 'Present' `
                        -Text $script:testText `
                        -IgnoreNameCase:$true `
                        -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and values match but are different case and IgnoreValueCase is False' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should exist and values match but are different case and IgnoreValueCase is True' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

                It 'Should not throw an exception' {
                    { $script:result = Test-TargetResource `
                            -Path $script:testTextFile `
                            -Name $script:testName `
                            -Ensure 'Present' `
                            -Text $script:testText.ToUpper() `
                            -IgnoreValueCase:$true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file exists and contains a matching key that should not exist' {
                Mock -CommandName Test-Path `
                    -MockWith { $true }

                Mock -CommandName Get-Content `
                    -MockWith { $script:testFileExpectedTextContent }

                Mock -CommandName Get-FileEncoding `
                    -MockWith { $script:testCompliantEncoding.Encoding }

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
                    Assert-MockCalled -CommandName Assert-ParametersValid `
                        -Scope Context `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-Content `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-FileEncoding `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_KeyValuePairFile\Assert-ParametersValid' {
            BeforeAll {
                Mock -CommandName Split-Path -MockWith { $script:testTextFile }
            }

            Context 'When the file parent path exists' {
                Mock -CommandName Test-Path -MockWith { $true }

                It 'Should not throw an exception' {
                    { Assert-ParametersValid `
                            -Path $script:testTextFile `
                            -Name $script:testName `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Split-Path `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Test-Path `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
                }
            }

            Context 'When the file parent path does not exist' {
                Mock -CommandName Test-Path -MockWith { $false }

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.FileParentNotFoundError -f $script:testTextFile) `
                    -ArgumentName 'Path'

                It 'Should throw expected exception' {
                    { Assert-ParametersValid `
                            -Path $script:testTextFile `
                            -Name $script:testName `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Split-Path `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1

                    Assert-MockCalled -CommandName Test-Path `
                        -Scope Context `
                        -ParameterFilter { $path -eq $script:testTextFile } `
                        -Exactly -Times 1
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
