Describe "Get-IniContent" {

    Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

    # assert
    Context "Alias" {
        It "Get-IniContent alias should exist" {
            Get-Alias -Definition Get-IniContent | Where-Object {$_.name -eq "gic"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }

}
