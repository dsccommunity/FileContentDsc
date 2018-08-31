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
    -ResourceName 'DSR_ReplaceText' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Retrieves the current state of the text file.

    .PARAMETER Path
        The path to the text file to replace the string in.

    .PARAMETER Search
        The RegEx string to use to search the text file.
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
        $Search
    )

    Assert-ParametersValid @PSBoundParameters

    $fileContent = Get-Content -Path $Path -Raw

    Write-Verbose -Message ($localizedData.SearchForTextMessage -f `
            $Path, $Search)

    $text = ''

    # Search the file content for any matches
    $results = [regex]::Matches($fileContent, $Search)

    if ($results.Count -eq 0)
    {
        # No matches found - already in state
        Write-Verbose -Message ($localizedData.StringNotFoundMessage -f `
                $Path, $Search)
    }
    else
    {
        $text = ($results.Value -join ',')

        Write-Verbose -Message ($localizedData.StringMatchFoundMessage -f `
                $Path, $Search, $text)
    } # if

    return @{
        Path   = $Path
        Search = $Search
        Type   = 'Text'
        Text   = $text
    }
}

<#
    .SYNOPSIS
        Replaces text the matches the RegEx in the file.

    .PARAMETER Path
        The path to the text file to replace the string in.

    .PARAMETER Search
        The RegEx string to use to search the text file.

    .PARAMETER Type
        Specifies the value type to use as the replacement string. Defaults to 'Text'.

    .PARAMETER Text
        The text to replace the text identifed by the RegEx.
        Only used when Type is set to 'Text'.

    .PARAMETER Secret
        The secret text to replace the text identified by the RegEx.
        Only used when Type is set to 'Secret'.
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
        $Search,

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
        $Secret
    )

    Assert-ParametersValid @PSBoundParameters

    $fileContent = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue

    if ($Type -eq 'Secret')
    {
        Write-Verbose -Message ($localizedData.StringReplaceSecretMessage -f `
                $Path)

        $Text = $Secret.GetNetworkCredential().Password
    }
    else
    {
        Write-Verbose -Message ($localizedData.StringReplaceTextMessage -f `
                $Path, $Text)
    } # if

    if ($null -eq $fileContent)
    {
        # configuration file does not exist
        $fileContent = $Text
    }
    elseif ( [regex]::Matches($fileContent, $Search).Count -eq 0 )
    {
        # configuration file exists but Text does not exist so lets add it
        $fileContent = "{0}`n`r{1}" -f $fileContent, $Text
    }
    else
    {
        # configuration file exists but Text not in a desired state so lets update it
        $fileContent = $fileContent -Replace $Search, $Text
    }

    Set-Content `
        -Path $Path `
        -Value $fileContent `
        -Force
        #-NoNewline `

}

<#
    .SYNOPSIS
        Tests if any text in the file matches the RegEx.

    .PARAMETER Path
        The path to the text file to replace the string in.

    .PARAMETER Search
        The RegEx string to use to search the text file.

    .PARAMETER Type
        Specifies the value type to use as the replacement string. Defaults to 'Text'.

    .PARAMETER Text
        The text to replace the text identifed by the RegEx.
        Only used when Type is set to 'Text'.

    .PARAMETER Secret
        The secret text to replace the text identified by the RegEx.
        Only used when Type is set to 'Secret'.
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
        $Search,

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
        $Secret
    )

    Assert-ParametersValid @PSBoundParameters

    # Check if file being managed exists. If not return $False.
    if (-not (Test-Path -Path $Path))
    {
        return $false
    }

    $fileContent = Get-Content -Path $Path -Raw

    Write-Verbose -Message ($localizedData.SearchForTextMessage -f `
            $Path, $Search)

    # Search the file content for any matches
    $results = [regex]::Matches($fileContent, $Search)

    if ($results.Count -eq 0)
    {
        # No matches found - already in state
        Write-Verbose -Message ($localizedData.StringNotFoundMessage -f `
                $Path, $Search)

        return $false
    }

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    if ($Type -eq 'Secret')
    {
        $Text = $Secret.GetNetworkCredential().Password
    } # if

    foreach ($result in $results)
    {
        if ($result.Value -ne $Text)
        {
            $desiredConfigurationMatch = $false
        } # if
    } # foreach

    if ($desiredConfigurationMatch)
    {
        Write-Verbose -Message ($localizedData.StringNoReplacementMessage -f `
                $Path, $Search)
    }
    else
    {
        Write-Verbose -Message ($localizedData.StringReplacementRequiredMessage -f `
                $Path, $Search)
    } # if

    return $desiredConfigurationMatch
}

<#
    .SYNOPSIS
        Validates the parameters that have been passed are valid.
        If they are not valid then an exception will be thrown.

    .PARAMETER Path
        The path to the text file to replace the string in.

    .PARAMETER Search
        The RegEx string to use to search the text file.

    .PARAMETER Type
        Specifies the value type to use as the replacement string. Defaults to 'Text'.

    .PARAMETER Text
        The text to replace the text identifed by the RegEx.
        Only used when Type is set to 'Text'.

    .PARAMETER Secret
        The secret text to replace the text identified by the RegEx.
        Only used when Type is set to 'Secret'.
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
        $Search,

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
        $Secret
    )

    # Does the file's parent path exist?
    $parentPath = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $parentPath))
    {
        New-InvalidArgumentException `
            -Message ($localizedData.FileParentNotFoundError -f $parentPath) `
            -ArgumentName 'Path'
    } # if
}

Export-ModuleMember -Function *-TargetResource
