<#
    .Synopsis
        This Module contains functions to manage INI files

    .Notes
        Author       : Oliver Lipkau <https://github.com/lipkau>
        Contributers : https://github.com/lipkau/PsIni/graphs/contributors
        Homepage     : http://lipkau.github.io/PsIni/

#>

# Name of the Section, in case the ini file had none
# Available in the scope of the module as `$script:NoSection`
$script:NoSection = "_"

# public functions
. "$PSScriptRoot\Public\ConvertFrom-Ini.ps1"
. "$PSScriptRoot\Public\ConvertTo-Ini.ps1"
. "$PSScriptRoot\Public\Import-Ini.ps1"
. "$PSScriptRoot\Public\Export-Ini.ps1"

# private functions
. "$PSScriptRoot\Private\Get-AllowedEncoding.ps1"
. "$PSScriptRoot\Private\Invoke-ConditionalParameterValidationEncoding.ps1"
. "$PSScriptRoot\Private\Invoke-ConditionalParameterValidationPath.ps1"
. "$PSScriptRoot\Private\isNumeric.ps1"
. "$PSScriptRoot\Private\Out-Keys.ps1"
. "$PSScriptRoot\Private\Remove-EmptyLines.ps1"
. "$PSScriptRoot\Private\Write-DebugMessage.ps1"
