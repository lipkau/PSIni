# Enforce WorkingDir
#--------------------------------------------------
$Script:ScriptDir = split-path -parent $PSCommandPath
Set-Location $ScriptDir

$testFile = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
# functions and tests stored in separate directories; adjusting dot-sourcing
. "$($ScriptDir -replace 'Tests', 'Functions')\$testFile"

Describe "Get-IniContent" {

    # assert
    Context "Alias" {
        It "Get-IniContent alias should exist" {
            (Get-Alias -Definition Get-IniContent).name | Should Be "get-ini"
        }
    }

}