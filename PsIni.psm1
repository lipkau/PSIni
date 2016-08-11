<#
    .Synopsis
        This Module contains functions to manage INI files

    .Description
        This Module contains functions to manage INI files

    .Notes
        Author       : Oliver Lipkau <oliver@lipkau.net>
        Contributers : Craig Buchanan <https://github.com/craibuc>
                       Colin Bate <https://github.com/colinbate>
                       Sean Seymour <https://github.com/seanjseymour>

        Homepage     : http://lipkau.github.io/PsIni/

#>

$PsIniModuleHome = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

. "$PsIniModuleHome\Functions\Get-IniContent.ps1"

. "$PsIniModuleHome\Functions\Out-IniFile.ps1"

. "$PsIniModuleHome\Functions\Comment-IniContent.ps1"

. "$PsIniModuleHome\Functions\Uncomment-IniContent.ps1"

. "$PsIniModuleHome\Functions\Remove-IniContent.ps1"

. "$PsIniModuleHome\Functions\Update-IniContent.ps1"
