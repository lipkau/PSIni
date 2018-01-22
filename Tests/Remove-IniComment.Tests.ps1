Describe "Remove-IniComment" {

    Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

    # assert
    Context "Alias" {
        It "Remove-IniComment alias should exist" {
            Get-Alias -Definition Remove-IniComment | Where-Object {$_.name -eq "ric"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
}
