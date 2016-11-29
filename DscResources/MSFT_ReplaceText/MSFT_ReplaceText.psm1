# Suppressed as per PSSA Rule Severity guidelines for unit/integration tests:
# https://github.com/PowerShell/DscResources/blob/master/PSSARuleSeverities.md
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

Set-StrictMode -Version 'Latest'

Import-Module `
    -Name (Join-Path `
        -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_ReplaceText'

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

    Assert-ParametersValid

    $fileContent = Get-Content -Path $Path

    Write-Verbose -Message ($script:localizedData.SearchForTextMessage -f `
        $Path,$Search)

    $text = ''

    if ($fileContent -match $Search)
    {
        $text = $Matches.Values

        Write-Verbose -Message ($script:localizedData.StringMatchFoundMessage -f `
            $Path,$Search,$text)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.StringNotFoundMessage -f `
            $Path,$Search)
    } # if

    return @{
        Path       = $Path
        Search     = $Search
        Type       = 'Text'
        Text       = $text
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
        Specifies the value type to use as the replacement string.

    .PARAMETER Text
        The text to replace the text identifed by the RegEx.
        Only used when Type is set to 'Text'.

    .PARAMETER Password
        The password to replace the text identified by the RegEx.
        Only used when Type is set to 'Password'.
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

        [ValidateSet('Text', 'Password')]
        [String]
        $Type = 'Text',

        [String]
        $Text,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Password
    )

    Assert-ParametersValid

    $fileContent = Get-Content -Path $Path

    switch ($Type)
    {
        'Text'
        {
            Write-Verbose -Message ($script:localizedData.StringReplaceTextMessage -f `
                $Path,$Text)

            $fileContent = $fileContent -Replace $Search,$Text
            break
        } # 'Text'
        'Password'
        {
            Write-Verbose -Message ($script:localizedData.StringReplacePasswordMessage -f `
                $Path)

            $fileContent = $fileContent -Replace $Search,$Password.Password
            break
        } # 'Password'
    } # switch

    Set-Content `
        -Path $Path `
        -Value $fileContent `
        -Force
}

<#
    .SYNOPSIS
        Tests if any text in the file matches the RegEx.

    .PARAMETER Path
        The path to the text file to replace the string in.

    .PARAMETER Search
        The RegEx string to use to search the text file.

    .PARAMETER Type
        Specifies the value type to use as the replacement string.

    .PARAMETER Text
        The text to replace the text identifed by the RegEx.
        Only used when Type is set to 'Text'.

    .PARAMETER Password
        The password to replace the text identified by the RegEx.
        Only used when Type is set to 'Password'.
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

        [ValidateSet('Text', 'Password')]
        [String]
        $Type = 'Text',

        [String]
        $Text,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Password
    )

    Assert-ParametersValid

    $fileContent = Get-Content -Path $Path

    Write-Verbose -Message ($script:localizedData.SearchForTextMessage -f `
        $Path,$Search)

    if (-not ($fileContent -match $Search)) {
        Write-Verbose -Message ($script:localizedData.StringNotFoundMessage -f `
            $Path,$Search)

        return $false
    } # if

    switch ($Type)
    {
        'Text'
        {
            if ($Matches.Values -eq $Text)
            {
                Write-Verbose -Message ($script:localizedData.StringAlreadyMatchesTextMessage -f `
                    $Path,$Search,$Text)

                return $false
            } # if
            break
        } # 'Text'
        'Password'
        {
            if ($Matches.Values -eq $Password.Password)
            {
                Write-Verbose -Message ($script:localizedData.StringAlreadyMatchesPasswordMessage -f `
                    $Path,$Search)

                return $false
            } # if
            break
        } # 'Password'
    } # switch

    Write-Verbose -Message ($script:localizedData.StringMatchFoundMessage -f `
        $Path,$Search,$Matches.Values)

    return $true
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
        Specifies the value type to use as the replacement string.

    .PARAMETER Text
        The text to replace the text identifed by the RegEx.
        Only used when Type is set to 'Text'.

    .PARAMETER Password
        The password to replace the text identified by the RegEx.
        Only used when Type is set to 'Password'.
#>
function Assert-ParametersValid
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

        [ValidateSet('Text', 'Password')]
        [String]
        $Type = 'Text',

        [String]
        $Text,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Password
    )

    # Does the file in path exist?
    if (-not (Test-Path -Path $Path))
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.FileNotFoundError -f $Path) `
            -ArgumentName 'Path'
    } # if
}

Export-ModuleMember -Function '*-TargetResource'
