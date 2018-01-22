Describe "Set-IniContent" {

    Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

    # assert
    Context "Alias" {
        It "Set-IniContent alias should exist" {
            Get-Alias -Definition Set-IniContent | Where-Object {$_.name -eq "sic"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
}
