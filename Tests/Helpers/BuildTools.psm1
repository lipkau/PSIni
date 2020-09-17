#requires -Modules @{ModuleName='PowerShellGet';ModuleVersion='1.6.0'}

function Install-Dependency {
    [CmdletBinding()]
    param(
        [ValidateSet("CurrentUser", "AllUsers")]
        $Scope = "CurrentUser"
    )

    [Microsoft.PowerShell.Commands.ModuleSpecification[]]$RequiredModules = Import-LocalizedData -BaseDirectory "$PSScriptRoot/../.." -FileName "build.requirements.psd1"
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

Export-ModuleMember -Function * -Alias *
