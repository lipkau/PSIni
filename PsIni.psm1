<#
    .Synopsis
        This Module contains functions to manage INI files

    .Description
        This Module contains functions to manage INI files

    .Notes
        Author       : Oliver Lipkau <oliver@lipkau.net>
        Contributers : Craig Buchanan <https://github.com/craibuc>
                       Colin Bate <https://github.com/colinbate>

        Homepage     : http://lipkau.github.io/PsIni/

#>

$ScriptPath = $MyInvocation.MyCommand.Path
$PsIniModuleHome = split-path -parent $ScriptPath

. "$PsIniModuleHome\Functions\Get-IniContent.ps1"

. "$PsIniModuleHome\Functions\Out-IniFile.ps1"