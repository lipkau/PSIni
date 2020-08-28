#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

New-Module PesterEx -ScriptBlock {
    function BeforeDiscovery ([ScriptBlock] $ScriptBlock) {
        . $ScriptBlock
    }
} -PassThru | Import-Module

Describe "General project validation" -Tag Unit {
    Describe "Public functions" {
        BeforeAll {
            $moduleRoot = (Join-Path $PSScriptRoot "../PSIni")

            Remove-Module PsIni -ErrorAction SilentlyContinue
            Import-Module $moduleRoot -Force -ErrorAction Stop

            $module = Get-Module PsIni
            $testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
        }
        BeforeDiscovery {
            $moduleRoot = (Join-Path $PSScriptRoot "../PSIni")
            $publicFunctions = Get-ChildItem "$moduleRoot/Public/*.ps1" | Foreach-Object { @{ BaseName = $_.BaseName } }
        }

        It "has a test file for <BaseName>" -TestCases $publicFunctions {
            param($BaseName)
            $expectedTestFile = "$BaseName.Unit.Tests.ps1"
            $testFiles.Name | Should -Contain $expectedTestFile
        }

        It "exports <BaseName>" -TestCases $publicFunctions {
            param($BaseName)
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Contain $expectedFunctionName
        }
    }

    Describe "Private functions" {
        BeforeAll {
            $moduleRoot = (Join-Path $PSScriptRoot "../PSIni")

            Remove-Module PsIni -ErrorAction SilentlyContinue
            Import-Module $moduleRoot -Force -ErrorAction Stop

            $module = Get-Module PsIni
            # $testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
        }
        BeforeDiscovery {
            $moduleRoot = (Join-Path $PSScriptRoot "../PSIni")
            $privateFunctions = Get-ChildItem "$moduleRoot/Private/*.ps1" | Foreach-Object { @{ BaseName = $_.BaseName } }
        }

        # TODO: have one test file for each private function
        <# It "has a test file for <BaseName>" -TestCases $privateFunctions {
                param($BaseName)
                $expectedTestFile = "$BaseName.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            } #>

        It "does not export <BaseName>" -TestCases $privateFunctions {
            param($BaseName)
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Not -Contain $expectedFunctionName
        }
    }

    Describe "Project stucture" {
        BeforeAll {
            $moduleRoot = (Join-Path $PSScriptRoot "../PSIni")

            Remove-Module PsIni -ErrorAction SilentlyContinue
            Import-Module $moduleRoot -Force -ErrorAction Stop
        }

        It "has all the public functions as a file in 'PsIni/Public'" {
            $publicFunctions = (Get-Module -Name PsIni).ExportedFunctions.Keys

            foreach ($function in $publicFunctions) {
                (Get-ChildItem "$moduleRoot/Public").BaseName | Should -Contain $function
            }
        }
    }
}
