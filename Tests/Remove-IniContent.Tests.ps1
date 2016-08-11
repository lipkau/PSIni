# Enforce WorkingDir
#--------------------------------------------------
$Script:ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -parent
Set-Location $ScriptDir

$testFile = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
# functions and tests stored in separate directories; adjusting dot-sourcing
. "$($ScriptDir -replace 'Tests', 'Functions')\$testFile"

Describe "Remove-IniContent" {

    # assert
    Context "Alias" {
        It "Remove-IniContent alias should exist" {
            Get-Alias -Definition Remove-IniContent | Where-Object {$_.name -eq "remove-ini"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
}
