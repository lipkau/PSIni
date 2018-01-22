Describe "Out-IniFile" {

    Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

    Context "Alias" {

        # assert
        It "Out-IniFile alias should exist" {
            Get-Alias -Definition Out-IniFile | Where-Object {$_.name -eq "oif"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }

    }

}
