[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'FileContentDsc' `
    -DscResourceName 'MSFT_IniSettingsFile' `
    -TestType 'Integration'

try
{
    Describe 'IniSettingsFile Integration Tests' {
        $script:confgurationFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_IniSettingsFile.config.ps1'
        $script:configurationName = 'IniSettingsFile'
        $script:testTextFile = Join-Path -Path $TestDrive -ChildPath 'TestFile.ini'
        $script:testText = 'Test Text'
        $script:testSecret = 'Test Secret'
        $script:testSection = 'Section One'
        $script:testKey = 'SettingTwo'
        $script:testSecureSecret = ConvertTo-SecureString -String $script:testSecret -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecret)

        $script:testFileContent = @"
[Section One]
SettingOne=Value1
SettingTwo=Value2

[Section Two]
SettingThree=Value3

"@

        $script:testFileExpectedTextContent = @"
[Section One]
SettingOne=Value1
SettingTwo=$($script:testText)

[Section Two]
SettingThree=Value3

"@

        $script:testFileExpectedSecretContent = @"
[Section One]
SettingOne=Value1
SettingTwo=$($script:testSecret)

[Section Two]
SettingThree=Value3

"@

        # Load the DSC config to use for testing
        . $script:confgurationFilePath -ConfigurationName $script:configurationName

        Context 'An INI settings file containing an entry to be replaced with another text string' {
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
                                Section  = $script:testSection
                                Key      = $script:testKey
                                Type     = 'Text'
                                Text     = $script:testText
                            }
                        )
                    }

                    & $script:configurationName `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    Start-DscConfiguration -Path $TestDrive -ErrorAction 'Stop' -Wait -Force -Verbose
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:currentDscConfig = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $script:current = $script:currentDscConfig | Where-Object {
                    $_.ConfigurationName -eq $script:configurationName
                }
                $current.Path             | Should Be $script:testTextFile
                $current.Section          | Should Be $script:testSection
                $current.Key              | Should Be $script:testKey
                $current.Type             | Should Be 'Text'
                $current.Text             | Should Be $script:testText
            }

            It 'Should be convert the file content to match expected content' {
                Get-Content -Path $script:testTextFile -Raw | Should Be $script:testFileExpectedTextContent
            }

            AfterAll {
                if (Test-Path -Path $script:testTextFile)
                {
                    Remove-Item -Path $script:testTextFile -Force
                }
            }
        }

        Context 'An INI settings file containing an entry to be replaced with another secret text string' {
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
                                Section                     = $script:testSection
                                Key                         = $script:testKey
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
                } | Should Not Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $script:currentDscConfig = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $script:current = $script:currentDscConfig | Where-Object {
                    $_.ConfigurationName -eq $script:configurationName
                }
                $current.Path             | Should Be $script:testTextFile
                $current.Section          | Should Be $script:testSection
                $current.Key              | Should Be $script:testKey
                $current.Type             | Should Be 'Text'
                $current.Text             | Should Be $script:testSecret
            }

            It 'Should be convert the file content to match expected content' {
                Get-Content -Path $script:testTextFile -Raw | Should Be $script:testFileExpectedSecretContent
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
