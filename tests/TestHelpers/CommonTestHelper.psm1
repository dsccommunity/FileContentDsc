<#
    .SYNOPSIS
        Returns an invalid argument exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function Get-InvalidArgumentRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
        $ArgumentName )
    $newObjectParams = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Returns an invalid operation exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function Get-InvalidOperationRecord
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $Message)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
    }
    elseif ($null -eq $ErrorRecord)
    {
        $invalidOperationException =
        New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message )
    }
    else
    {
        $invalidOperationException =
        New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message,
            $ErrorRecord.Exception )
    }

    $newObjectParams = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
            'InvalidOperation', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Gets file encoding. Defaults to ASCII.

    .DESCRIPTION
        The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
        Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx

    .EXAMPLE
        Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'}
        This command gets ps1 files in current directory where encoding is not ASCII

    .EXAMPLE
        Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'} | `
            foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
        Same as previous example but fixes encoding using set-content
#>
function Get-FileEncoding
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Path
    )

    [System.Byte[]] $byte = Get-Content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path

    if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf)
    {
        return 'UTF8'
    }
    elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe)
    {
        return 'UTF32'
    }
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
    {
        return 'BigEndianUnicode'
    }
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
    {
        return 'BigEndianUTF32'
    }
    else
    {
        return 'ASCII'
    }
}

Export-ModuleMember -Function `
    'Get-InvalidArgumentRecord', `
    'Get-InvalidOperationRecord', `
    'Get-FileEncoding'
