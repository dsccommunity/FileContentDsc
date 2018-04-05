[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'FileContentDsc' `
    -DscResourceName 'DSR_KeyValuePairFile' `
    -TestType 'Integration'

try
{
    Describe 'KeyValuePairFile Integration Tests' {
        $script:confgurationFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'DSR_KeyValuePairFile.config.ps1'
        $script:configurationName = 'KeyValuePairFile'
        $script:testTextFile = Join-Path -Path $TestDrive -ChildPath 'TestFile.txt'
        $script:testName = 'Setting.Two'
        $script:testText = 'Test Text'
        $script:testSecret = 'Test Secret'
        $script:testSecureSecret = ConvertTo-SecureString -String $script:testSecret -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecret)

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

        # Load the DSC config to use for testing
        . $script:confgurationFilePath -ConfigurationName $script:configurationName

        Context 'A text file containing the key to be replaced with another text string' {
            BeforeAll {
                # Create the text file to use for testing
                Set-Content `
                    -Path $script:testTextFile `
                    -Value $script:testFileContent `
                    -NoNewline `
                    -Force
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName = 'localhost'
                                Path     = $script:testTextFile
                                Name     = $script:testName
                                Ensure   = 'Present'
                                Type     = 'Text'
                                Text     = $script:testText
                            }
                        )
                    }

                    & $script:configurationName `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    Start-DscConfiguration -Path $TestDrive -ErrorAction 'Stop' -Wait -Force -Verbose
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:currentDscConfig = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $script:current = $script:currentDscConfig | Where-Object {
                    $_.ConfigurationName -eq $script:configurationName
                }
                $current.Path             | Should -Be $script:testTextFile
                $current.Name             | Should -Be $script:testName
                $current.Ensure           | Should -Be 'Present'
                $current.Type             | Should -Be 'Text'
                $current.Text             | Should -Be "$($script:testText),$($script:testText),$($script:testText)"
            }

            It 'Should be convert the file content to match expected content' {
                Get-Content -Path $script:testTextFile -Raw | Should -Be $script:testFileExpectedTextContent
            }

            AfterAll {
                if (Test-Path -Path $script:testTextFile)
                {
                    Remove-Item -Path $script:testTextFile -Force
                }
            }
        }

        Context 'A text file containing the key to be replaced with another secret text string' {
            BeforeAll {
                # Create the text file to use for testing
                Set-Content `
                    -Path $script:testTextFile `
                    -Value $script:testFileContent `
                    -NoNewline `
                    -Force
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName                    = 'localhost'
                                Path                        = $script:testTextFile
                                Name                        = $script:testName
                                Ensure                      = 'Present'
                                Type                        = 'Secret'
                                Secret                      = $script:testSecretCredential
                                PsDscAllowPlainTextPassword = $true
                            }
                        )
                    }

                    & $script:configurationName `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    Start-DscConfiguration -Path $TestDrive -ErrorAction 'Stop' -Wait -Force -Verbose
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:currentDscConfig = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $script:current = $script:currentDscConfig | Where-Object {
                    $_.ConfigurationName -eq $script:configurationName
                }
                $current.Path             | Should -Be $script:testTextFile
                $current.Name             | Should -Be $script:testName
                $current.Ensure           | Should -Be 'Present'
                $current.Type             | Should -Be 'Text'
                $current.Text             | Should -Be "$($script:testSecret),$($script:testSecret),$($script:testSecret)"
            }

            It 'Should be convert the file content to match expected content' {
                Get-Content -Path $script:testTextFile -Raw | Should -Be $script:testFileExpectedSecretContent
            }

            AfterAll {
                if (Test-Path -Path $script:testTextFile)
                {
                    Remove-Item -Path $script:testTextFile -Force
                }
            }
        }

        Context 'A text file containing the key to have the keys removed' {
            BeforeAll {
                # Create the text file to use for testing
                Set-Content `
                    -Path $script:testTextFile `
                    -Value $script:testFileContent `
                    -NoNewline `
                    -Force
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName = 'localhost'
                                Path     = $script:testTextFile
                                Name     = $script:testName
                                Ensure   = 'Absent'
                            }
                        )
                    }

                    & $script:configurationName `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    Start-DscConfiguration -Path $TestDrive -ErrorAction 'Stop' -Wait -Force -Verbose
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:currentDscConfig = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $script:current = $script:currentDscConfig | Where-Object {
                    $_.ConfigurationName -eq $script:configurationName
                }
                $current.Path             | Should -Be $script:testTextFile
                $current.Name             | Should -Be $script:testName
                $current.Ensure           | Should -Be 'Absent'
                $current.Type             | Should -Be 'Text'
                $current.Text             | Should -BeNullOrEmpty
            }

            It 'Should be convert the file content to match expected content' {
                Get-Content -Path $script:testTextFile -Raw | Should -Be $script:testFileExpectedAbsentContent
            }

            AfterAll {
                if (Test-Path -Path $script:testTextFile)
                {
                    Remove-Item -Path $script:testTextFile -Force
                }
            }
        }
    }
}
finally
{
    Exit-DscResourceTestEnvironment -TestEnvironment $script:testEnvironment
    Remove-Module -Name CommonTestHelper
}
