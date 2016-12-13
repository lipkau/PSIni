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
                       Alexis Côté <https://github.com/popojargo>

        Homepage     : http://lipkau.github.io/PsIni/

#>

$PsIniModuleHome = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Name of the Section, in case the ini file had none
# Available in the scope of the module as `$script:NoSection`
$script:NoSection = "_"

# public functions
. "$PsIniModuleHome\Functions\Get-IniContent.ps1"
. "$PsIniModuleHome\Functions\Out-IniFile.ps1"
. "$PsIniModuleHome\Functions\Add-IniComment.ps1"
. "$PsIniModuleHome\Functions\Remove-IniComment.ps1"
. "$PsIniModuleHome\Functions\Remove-IniEntry.ps1"
. "$PsIniModuleHome\Functions\Set-IniContent.ps1"

# private functions
. "$PsIniModuleHome\Functions\Convert-IniCommentToEntry.ps1"
. "$PsIniModuleHome\Functions\Convert-IniEntryToComment.ps1"
