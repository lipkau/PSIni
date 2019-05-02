<#
    .Synopsis
        This Module contains functions to manage INI files

    .Description
        This Module contains functions to manage INI files

    .Notes
        Author       : Oliver Lipkau <https://github.com/lipkau>
        Contributers : Craig Buchanan <https://github.com/craibuc>
                       Colin Bate <https://github.com/colinbate>
                       Sean Seymour <https://github.com/seanjseymour>
                       Alexis Côté <https://github.com/popojargo>

        Homepage     : http://lipkau.github.io/PsIni/

#>

# Name of the Section, in case the ini file had none
# Available in the scope of the module as `$script:NoSection`
$script:NoSection = "_"

# public functions
. "$PSScriptRoot\Public\Import-Ini.ps1"
. "$PSScriptRoot\Public\Export-Ini.ps1"
. "$PSScriptRoot\Functions\Add-IniComment.ps1"
. "$PSScriptRoot\Functions\Remove-IniComment.ps1"
. "$PSScriptRoot\Functions\Remove-IniEntry.ps1"
. "$PSScriptRoot\Functions\Set-IniContent.ps1"

# private functions
. "$PSScriptRoot\Functions\Convert-IniCommentToEntry.ps1"
. "$PSScriptRoot\Functions\Convert-IniEntryToComment.ps1"
