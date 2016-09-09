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

. "$PsIniModuleHome\Functions\Convert-IniCommentToEntry.ps1"

. "$PsIniModuleHome\Functions\Convert-IniEntryToComment.ps1"

. "$PsIniModuleHome\Functions\Get-IniContent.ps1"

. "$PsIniModuleHome\Functions\Out-IniFile.ps1"

. "$PsIniModuleHome\Functions\Add-IniComment.ps1"

. "$PsIniModuleHome\Functions\Remove-IniComment.ps1"

. "$PsIniModuleHome\Functions\Remove-IniEntry.ps1"

. "$PsIniModuleHome\Functions\Set-IniContent.ps1"
