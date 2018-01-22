Describe "Remove-IniEntry" {

    Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

    # assert
    Context "Alias" {
        It "Remove-IniEntry alias should exist" {
            Get-Alias -Definition Remove-IniEntry | Where-Object {$_.name -eq "rie"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
}
