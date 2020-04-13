[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

$script:dscModuleName = 'FileContentDsc'
$script:dscResourceName = 'DSC_KeyValuePairFile'

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
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

try
{
    Describe "$($script:dscResourceName)_Integration" {
        $script:confgurationFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'DSC_KeyValuePairFile.config.ps1'
        $script:configurationName = 'KeyValuePairFile'
        $script:testTextFile = Join-Path -Path $TestDrive -ChildPath 'TestFile.txt'
        $script:testName = 'Setting.Two'
        $script:testText = 'Test Text'
        $script:testSecret = 'Test Secret'
        $script:testSecureSecret = ConvertTo-SecureString -String $script:testSecret -AsPlainText -Force
        $script:testSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Dummy', $script:testSecureSecret)

        $script:fileEncodingParameters = @{
            Path     = $script:testTextFile
            Encoding = 'ASCII'
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

    $script:testFileExpectedEmptyContent = @"
$($script:testName)=$($script:testText)
"@

        # Load the DSC config to use for testing
        . $script:confgurationFilePath -ConfigurationName $script:configurationName

        Context 'When the key value pair text file contains a key value to be replaced with a text string' {
            BeforeAll {
                # Create the text file to use for testing
                Set-Content `
                    -Path $script:testTextFile `
                    -Value $script:testFileContent `
                    -NoNewline `
                    -Force
            }

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

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
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

        Context 'When the key value pair text file contains a key value to be replaced with a secret text string' {
            BeforeAll {
                # Create the text file to use for testing
                Set-Content `
                    -Path $script:testTextFile `
                    -Value $script:testFileContent `
                    -NoNewline `
                    -Force
            }

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

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
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

        Context 'When the key value pair text file contains a key that needs to be removed' {
            BeforeAll {
                # Create the text file to use for testing
                Set-Content `
                    -Path $script:testTextFile `
                    -Value $script:testFileContent `
                    -NoNewline `
                    -Force
            }

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

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
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

        Context 'When the key value pair text file requires encoding be changed' {
            BeforeAll {
                # Create the text file to use for testing
                Set-Content `
                    -Path $script:testTextFile `
                    -Value $script:testFileContent `
                    -Encoding $script:testNonCompliantEncoding.Encoding `
                    -NoNewline `
                    -Force
            }

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
                                Encoding = $script:fileEncodingParameters.Encoding
                            }
                        )
                    }

                    & $script:configurationName `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
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
                $current.Encoding         | Should -Be $script:fileEncodingParameters.Encoding
            }

            It 'Should convert file encoding to the expected type' {
                Get-FileEncoding -Path $script:testTextFile | Should -Be $script:fileEncodingParameters.Encoding
            }

            AfterAll {
                if (Test-Path -Path $script:testTextFile)
                {
                    Remove-Item -Path $script:testTextFile -Force
                }
            }
        }

        Context 'When the key value pair text file does not exist' {
            BeforeAll {
                # Make sure the test file does not exist
                Remove-Item -Path $script:testTextFile -Force -ErrorAction SilentlyContinue
            }

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

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
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
                $current.Text             | Should -Be $script:testText
            }

            It 'Should be convert the file content to match expected content' {
                Get-Content -Path $script:testTextFile -Raw | Should -Be $script:testFileExpectedEmptyContent
            }

            AfterAll {
                if (Test-Path -Path $script:testTextFile)
                {
                    Remove-Item -Path $script:testTextFile -Force
                }
            }
        }

        Context 'When the key value pair text file that is empty' {
            BeforeAll {
                # Make sure the test file is empty
                Set-Content `
                    -Path $script:testTextFile `
                    -Value '' `
                    -NoNewline `
                    -Force
                }

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

                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
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
                $current.Text             | Should -Be $script:testText
            }

            It 'Should be convert the file content to match expected content' {
                Get-Content -Path $script:testTextFile -Raw | Should -Be $script:testFileExpectedEmptyContent
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
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
