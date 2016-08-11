# Enforce WorkingDir
#--------------------------------------------------
$Script:ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -parent
Set-Location $ScriptDir

$testFile = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
# functions and tests stored in separate directories; adjusting dot-sourcing
. "$($ScriptDir -replace 'Tests', 'Functions')\$testFile"

Describe "Update-IniContent" {

    # assert
    Context "Alias" {
        It "Update-IniContent alias should exist" {
            Get-Alias -Definition Update-IniContent | Where-Object {$_.name -eq "update-ini"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
}
