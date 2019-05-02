Describe "Export-Ini" {

    Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

    Context "Alias" {

        # assert
        It "Export-Ini alias should exist" {
            Get-Alias -Definition Export-Ini | Where-Object {$_.name -eq "epini"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }

    }

}
