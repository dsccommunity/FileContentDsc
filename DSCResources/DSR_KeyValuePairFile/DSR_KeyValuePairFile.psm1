# Suppressed as per PSSA Rule Severity guidelines for unit/integration tests:
# https://github.com/PowerShell/DscResources/blob/master/PSSARuleSeverities.md
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

Set-StrictMode -Version 'Latest'

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Storage Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'FileContentDsc.Common' `
            -ChildPath 'FileContentDsc.Common.psm1'))

# Import the Storage Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'FileContentDsc.ResourceHelper' `
            -ChildPath 'FileContentDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'DSR_KeyValuePairFile' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Retrieves the current state of a key in a key value pair text file.

    .PARAMETER Path
        The path to the key value pair text file.

    .PARAMETER Name
        The name of the key.
#>
function Get-TargetResource
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
    )

    Assert-ParametersValid @PSBoundParameters

    $fileContent = Get-Content -Path $Path -Raw

    Write-Verbose -Message ($localizedData.SearchForKeyMessage -f `
            $Path, $Name)

    # Setup the Regex Options that will be used
    $regExOptions = [System.Text.RegularExpressions.RegexOptions]::Multiline

    # Search the key that matches the requested key
    $results = [regex]::Matches($fileContent, "^[\s]*$Name=([^\n\r]*)", $regExOptions)

    $ensure = 'Absent'
    $text = $null

    if ($results.Count -eq 0)
    {
        # No matches found
        Write-Verbose -Message ($localizedData.KeyNotFoundMessage -f `
                $Path, $Name)
    }
    else
    {
        # One of more key value pairs were found
        $ensure = 'Present'
        $textValues = @()

        foreach ($match in $results)
        {
            $textValues += $match.Groups[1].Value
        }

        $text = ($textValues -join ',')

        Write-Verbose -Message ($localizedData.KeyFoundMessage -f `
                $Path, $Name, $text)
    } # if

    return @{
        Path            = $Path
        Name            = $Name
        Ensure          = $ensure
        Type            = 'Text'
        Text            = $text
        IgnoreNameCase  = $false
        IgnoreValueCase = $false
    }
}

<#
    .SYNOPSIS
        Sets the current state of a key in a key value pair text file.

    .PARAMETER Path
        The path to the key value pair text file.

    .PARAMETER Name
        The name of the key.

    .PARAMETER Ensure
        Specifies the if the key value pair with the specified key should exist in the file.

    .PARAMETER Type
        Specifies the value type to use as the replacement string. Defaults to 'Text'.

    .PARAMETER Text
        The text to replace the value with in the identified key.
        Only used when Type is set to 'Text'.

    .PARAMETER Secret
        The secret text to replace the value with in the identified key.
        Only used when Type is set to 'Secret'.

    .PARAMETER IgnoreNameCase
        Ignore the case of the name of the key. Defaults to $False.

    .PARAMETER IgnoreValueCase
        Ignore the case of any text or secret when determining if it they need to be updated.
        Defaults to $False.
#>
function Set-TargetResource
{
    # Should process is called in a helper functions but not directly in Set-TargetResource
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('Text', 'Secret')]
        [String]
        $Type = 'Text',

        [Parameter()]
        [String]
        $Text,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Secret,

        [Parameter()]
        [System.Boolean]
        $IgnoreNameCase = $false,

        [Parameter()]
        [System.Boolean]
        $IgnoreValueCase = $false
    )

    Assert-ParametersValid @PSBoundParameters

    $fileContent = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue

    Write-Verbose -Message ($localizedData.SearchForKeyMessage -f `
            $Path, $Name)

    if ($Type -eq 'Secret')
    {
        $Text = $Secret.GetNetworkCredential().Password
    } # if

    if ($null -ne $fileContent)
    {
        # Determine the EOL characters used in the file
        $eolChars = Get-TextEolCharacter -Text $fileContent

        # Setup the Regex Options that will be used
        $regExOptions = [System.Text.RegularExpressions.RegexOptions]::Multiline
        if ($IgnoreNameCase)
        {
            $regExOptions += [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        }

        # Search the key that matches the requested key
        $results = [regex]::Matches($fileContent, "^[\s]*$Name=([^\n\r]*)", $regExOptions)

        if ($Ensure -eq 'Present')
        {
            # The key value pair should exist
            $keyValuePair = '{0}={1}{2}' -f $Name, $Text, $eolChars

            if ($results.Count -eq 0)
            {
                # The key value pair was not found so add it to the end of the file
                if (-not $fileContent.EndsWith($eolChars))
                {
                    $fileContent += $eolChars
                } # if

                $fileContent += $keyValuePair

                Write-Verbose -Message ($localizedData.KeyAddMessage -f `
                        $Path, $Name)
            }
            else
            {
                # The key value pair was found so update it
                $fileContent = [regex]::Replace($fileContent, "^[\s]*$Name=(.*)($eolChars*)", $keyValuePair, $regExOptions)

                Write-Verbose -Message ($localizedData.KeyUpdateMessage -f `
                        $Path, $Name)
            } # if
        }
        else
        {
            if ($results.Count -eq 0)
            {
                # The Key does not exists and should not so don't do anything
                return
            }
            else
            {
                # The Key exists in the file but should not so remove it
                $fileContent = [regex]::Replace($fileContent, "^[\s]*$Name=(.*)$eolChars", '', $regExOptions)

                Write-Verbose -Message ($localizedData.KeyRemoveMessage -f `
                        $Path, $Name)
            }
        } # if
    }
    else
    {
        $fileContent = '{0}={1}' -f $Name, $Text
    } # if

    Set-Content `
        -Path $Path `
        -Value $fileContent `
        -NoNewline `
        -Force
}

<#
    .SYNOPSIS
        Tests the current state of a key in a key value pair text file.

    .PARAMETER Path
        The path to the key value pair text file.

    .PARAMETER Name
        The name of the key.

    .PARAMETER Ensure
        Specifies the if the key value pair with the specified key should exist in the file.

    .PARAMETER Type
        Specifies the value type to use as the replacement string. Defaults to 'Text'.

    .PARAMETER Text
        The text to replace the value with in the identified key.
        Only used when Type is set to 'Text'.

    .PARAMETER Secret
        The secret text to replace the value with in the identified key.
        Only used when Type is set to 'Secret'.

    .PARAMETER IgnoreNameCase
        Ignore the case of the name of the key. Defaults to $False.

    .PARAMETER IgnoreValueCase
        Ignore the case of any text or secret when determining if it they need to be updated.
        Defaults to $False.
#>
function Test-TargetResource
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('Text', 'Secret')]
        [String]
        $Type = 'Text',

        [Parameter()]
        [String]
        $Text,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Secret,

        [Parameter()]
        [System.Boolean]
        $IgnoreNameCase = $false,

        [Parameter()]
        [System.Boolean]
        $IgnoreValueCase = $false
    )

    Assert-ParametersValid @PSBoundParameters

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    # Check if file being managed exists. If not return $False.
    if (-not (Test-Path -Path $Path))
    {
        return $false
    }

    $fileContent = Get-Content -Path $Path -Raw

    Write-Verbose -Message ($localizedData.SearchForKeyMessage -f `
            $Path, $Name)

    # Setup the Regex Options that will be used
    $regExOptions = [System.Text.RegularExpressions.RegexOptions]::Multiline
    if ($IgnoreNameCase)
    {
        $regExOptions += [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    }

    # Search the key that matches the requested key
    $results = [regex]::Matches($fileContent, "^[\s]*$Name=([^\n\r]*)", $regExOptions)

    if ($results.Count -eq 0)
    {
        # No matches found
        if ($Ensure -eq 'Present')
        {
            # The key value pairs should exist but do not
            Write-Verbose -Message ($localizedData.KeyNotFoundButShouldExistMessage -f `
                    $Path, $Name)

            $desiredConfigurationMatch = $false
        }
        else
        {
            # The key value pairs should exist and do
            Write-Verbose -Message ($localizedData.KeyNotFoundAndShouldNotExistMessage -f `
                    $Path, $Name)
        } # if
    }
    else
    {
        # One of more key value pairs were found
        if ($Ensure -eq 'Present')
        {
            # The key value pairs should exist - but check values
            if ($Type -eq 'Secret')
            {
                $Text = $Secret.GetNetworkCredential().Password
            } # if

            # Check each found key value pair and check it has the correct value
            foreach ($match in $results)
            {
                if (($IgnoreValueCase -and ($match.Groups[1].Value -ne $Text)) -or `
                    (-not $IgnoreValueCase -and ($match.Groups[1].Value -cne $Text)))
                {
                    $desiredConfigurationMatch = $false
                } #
            } # foreach

            if ($desiredConfigurationMatch)
            {
                Write-Verbose -Message ($localizedData.KeyFoundButNoReplacementMessage -f `
                        $Path, $Name)
            }
            else
            {
                Write-Verbose -Message ($localizedData.KeyFoundReplacementRequiredMessage -f `
                        $Path, $Name)
            } # if
        }
        else
        {
            # The key value pairs should not exist
            Write-Verbose -Message ($localizedData.KeyFoundButShouldNotExistMessage -f `
                    $Path, $Name)

            $desiredConfigurationMatch = $false
        } # if
    } # if

    return $desiredConfigurationMatch
}

<#
    .SYNOPSIS
        Validates the parameters that have been passed are valid.
        If they are not valid then an exception will be thrown.

    .PARAMETER Path
        The path to the key value pair text file.

    .PARAMETER Name
        The name of the key.

    .PARAMETER Ensure
        Specifies the if the key value pair with the specified key should exist in the file.

    .PARAMETER Type
        Specifies the value type to use as the replacement string. Defaults to 'Text'.

    .PARAMETER Text
        The text to replace the value with in the identified key.
        Only used when Type is set to 'Text'.

    .PARAMETER Secret
        The secret text to replace the value with in the identified key.
        Only used when Type is set to 'Secret'.

    .PARAMETER IgnoreNameCase
        Ignore the case of the name of the key. Defaults to $False.

    .PARAMETER IgnoreValueCase
        Ignore the case of any text or secret when determining if it they need to be updated.
        Defaults to $False.
#>
function Assert-ParametersValid
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('Text', 'Secret')]
        [String]
        $Type = 'Text',

        [Parameter()]
        [String]
        $Text,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Secret,

        [Parameter()]
        [System.Boolean]
        $IgnoreNameCase = $false,

        [Parameter()]
        [System.Boolean]
        $IgnoreValueCase = $false
    )

    # Does the file's parent path exist?
    $parentPath = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $parentPath))
    {
        New-InvalidArgumentException `
            -Message ($localizedData.FileParentNotFoundError -f $Path) `
            -ArgumentName 'Path'
    } # if
}

Export-ModuleMember -Function *-TargetResource
