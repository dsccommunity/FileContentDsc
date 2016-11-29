[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param ()

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'FileContentDsc' `
    -DscResourceName 'MSFT_ReplaceText' `
    -TestType 'Integration'

$script:testText = 'TestText'

$script:testPassword = 'TestPassword'

$script:testSearch = "Setting\.Two='(.)*'"

$script:testFileContent = @"
Setting1=Value1
Setting.Two='Value2'
Setting3.Test=Value3
"@

$script:testFileExpectedTextContent = @"
Setting1=Value1
Setting.Two='$($script:testText)'
Setting3.Test=Value3
"@

$script:testFileExpectedPasswordContent = @"
Setting1=Value1
Setting.Two='$($script:testPassword)'
Setting3.Test=Value3
"@

try
{
    Describe 'ReplaceText Integration Tests' {
        BeforeAll {
            $script:confgurationFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_ReplaceText.config.ps1'
        }

        It 'Should update the test text file' {
            $configurationName = 'ReplaceText'
            $testTextFile = Join-Path -Path $TestDrive -ChildPath 'TestFile.txt'

            Set-Content `
                -Path $testTextFile `
                -Value $script:testFileContent `
                -Force

            $resourceParameters = @{
                Path     = $testTextFile
                Search   = $script:testSearch
                Type     = 'Text'
                Text     = $script:testText
            }

            try
            {
                {
                    . $script:confgurationFilePath -ConfigurationName $configurationName
                    & $configurationName -OutputPath $TestDrive @resourceParameters
                    Start-DscConfiguration -Path $TestDrive -ErrorAction 'Stop' -Wait -Force
                } | Should Not Throw

                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw

                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq $configurationName
                }
                $current.Path             | Should Be $resourceParameters.Path
                $current.Search           | Should Be $resourceParameters.Search
                $current.Type             | Should Be 'Text'
                $current.Text             | Should Be "Setting.Two='$($script:testText)'"
            }
            finally
            {
                if (Test-Path -Path $testTextFile)
                {
                    Remove-Item -Path $testTextFile -Force
                }
            }
        }
    }
}
finally
{
    Exit-DscResourceTestEnvironment -TestEnvironment $script:testEnvironment
}
