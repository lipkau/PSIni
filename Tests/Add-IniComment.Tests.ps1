# Enforce WorkingDir
#--------------------------------------------------
$Script:ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -parent
$root = "$ScriptDir\.."
$Module = "$root\PSIni"
$Functions = "$root\PSIni\Functions"
Set-Location $ScriptDir

$testFile = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
# functions and tests stored in separate directories; adjusting dot-sourcing
. "$Functions\$testFile"

Describe "Add-IniComment" {

    # assert
    Context "Alias" {
        It "Add-IniComment alias should exist" {
            Get-Alias -Definition Add-IniComment | Where-Object {$_.name -eq "aic"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
}
