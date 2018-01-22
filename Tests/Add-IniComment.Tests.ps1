Describe "Add-IniComment" {

    Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

    # assert
    Context "Alias" {
        It "Add-IniComment alias should exist" {
            Get-Alias -Definition Add-IniComment | Where-Object {$_.name -eq "aic"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
}
