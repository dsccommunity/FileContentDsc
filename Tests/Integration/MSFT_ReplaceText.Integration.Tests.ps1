[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'FileContentDsc' `
    -DscResourceName 'MSFT_ReplaceText' `
    -TestType 'Integration'

try
{
    Describe 'ReplaceText Integration Tests' {
        $script:confgurationFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_ReplaceText.config.ps1'
        $script:configurationName = 'ReplaceText'
        $script:testTextFile = Join-Path -Path $TestDrive -ChildPath 'TestFile.txt'
        $script:testText = 'TestText'
        $script:testSecret = 'TestSecret'
        $script:testSearch = "Setting\.Two='(.)*'"
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

        # Load the DSC config to use for testing
        . $script:confgurationFilePath -ConfigurationName $script:configurationName

        Context 'A text file containinig text to be replaced with another text string' {
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
                                Search   = $script:testSearch
                                Type     = 'Text'
                                Text     = $script:testTextReplace
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
                $current.Search           | Should Be $script:testSearch
                $current.Type             | Should Be 'Text'
                $current.Text             | Should Be "$($script:testTextReplace),$($script:testTextReplace),$($script:testTextReplace)"
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

        Context 'A text file containinig text to be replaced with secret text' {
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
                                Search                      = $script:testSearch
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
                $current.Search           | Should Be $script:testSearch
                $current.Type             | Should Be 'Text'
                $current.Text             | Should Be "$($script:testSecretReplace),$($script:testSecretReplace),$($script:testSecretReplace)"
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
