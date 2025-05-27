#requires -Modules @{ModuleName='PowerShellGet';ModuleVersion='1.6.0'}

function Assert-True {
    [CmdletBinding( DefaultParameterSetName = 'ByBool' )]
    param(
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByScriptBlock' )]
        [ScriptBlock]$ScriptBlock,
        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByBool' )]
        [Bool]$Bool,
        [Parameter( Position = 1, Mandatory )]
        [String]$Message
    )

    if ($ScriptBlock) {
        $Bool = & $ScriptBlock
    }

    if (-not $Bool) {
        throw $Message
    }
}

function Test-ContainsAll {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory)]
        [String[]]$Haystack,
        [Parameter(Mandatory)]
        [String[]]$Needle
    )

    begin {
        $result = $Needle | ForEach-Object {
            if ($Haystack -notcontains $_) {
                return "missing"
            }
        }
        return -not ($result -eq "missing")
    }
}

function Get-HostInformation {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
    [OutputType([String], [String])]
    [CmdletBinding()]
    param()
    try {
        $script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
        $script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
        $script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
        $script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'
    }
    catch {}

    switch ($true) {
        { $IsWindows } {
            $OS = "Windows"
            if (-not ($IsCoreCLR)) {
                $OSVersion = $PSVersionTable.BuildVersion.ToString()
            }
        }
        { $IsLinux } {
            $OS = "Linux"
        }
        { $IsMacOs } {
            $OS = "OSX"
        }
        { $IsCoreCLR } {
            $OSVersion = $PSVersionTable.OS
        }
    }

    return $OS, $OSVersion
}

function Get-Dependency {
    [CmdletBinding()]
    param()

    [Microsoft.PowerShell.Commands.ModuleSpecification[]]$RequiredModules = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "build.requirements.psd1"
    $RequiredModules
}

function Install-Dependency {
    [CmdletBinding()]
    param(
        [ValidateSet("CurrentUser", "AllUsers")]
        $Scope = "CurrentUser"
    )

    $RequiredModules = Get-Dependency
    $Policy = (Get-PSRepository PSGallery).InstallationPolicy
    try {
        Set-PSRepository PSGallery -InstallationPolicy Trusted
        $RequiredModules | Install-Module -Scope $Scope -Repository PSGallery -SkipPublisherCheck -AllowClobber
    }
    finally {
        Set-PSRepository PSGallery -InstallationPolicy $Policy
    }
    $RequiredModules | Import-Module
}

function Remove-Utf8Bom {
    <#
    .SYNOPSIS
        Removes a UTF8 BOM from a file.
    .DESCRIPTION
        Removes a UTF8 BOM from a file if the BOM appears to be present.
        The UTF8 BOM is identified by the byte sequence 0xEF 0xBB 0xBF at the beginning of the file.
    .EXAMPLE
        Remove-Utf8Bom -Path c:\file.txt
        Remove a BOM from a single file.
    .EXAMPLE
        Get-ChildItem c:\folder -Recurse -File | Remove-Utf8Bom
        Remove the BOM from every file returned by Get-ChildItem.
    .LINK
        https://gist.github.com/indented-automation/5f6b87f31c438f14905f62961025758b
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param (
        # The path to a file which should be updated.
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias('FullName')]
        [String]$Path
    )

    begin {
        $encoding = [System.Text.UTF8Encoding]::new($false)
    }

    process {
        $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

        try {
            $bom = [Byte[]]::new(3)
            $stream = [System.IO.File]::OpenRead($Path)
            $null = $stream.Read($bom, 0, 3)
            $stream.Close()

            if ([BitConverter]::ToString($bom, 0) -eq 'EF-BB-BF') {
                [System.IO.File]::WriteAllLines(
                    $Path,
                    [System.IO.File]::ReadAllLines($Path),
                    $encoding
                )
            }
            else {
                Write-Verbose ('A UTF8 BOM was not detected on the file {0}' -f $Path)
            }
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}

Export-ModuleMember -Function * -Alias *
