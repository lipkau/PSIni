#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "General project validation" -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:module = Get-Module PSIni
        $script:moduleRoot = "$env:BHProjectPath/PSIni"
        $script:testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
        $script:publicFunctionFiles = Get-ChildItem "$moduleRoot/Public/*.ps1" | ForEach-Object { @{ BaseName = $_.BaseName } }
        $script:privateFunctionFiles = Get-ChildItem "$moduleRoot/Private/*.ps1" | ForEach-Object { @{ BaseName = $_.BaseName } }
    }

    Describe "Public functions" {

        It "has a test file for <BaseName>" -TestCases $publicFunctionFiles {
            param($BaseName)
            $expectedTestFile = "$BaseName.Unit.Tests.ps1"
            $testFiles.Name | Should -Contain $expectedTestFile
        }

        It "exports <BaseName>" -TestCases $publicFunctionFiles {
            param($BaseName)
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Contain $expectedFunctionName
        }
    }

    Describe "Private functions" {
        # TODO: have one test file for each private function
        <# It "has a test file for <BaseName>" -TestCases $privateFunctionFiles {
                param($BaseName)
                $expectedTestFile = "$BaseName.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            } #>

        It "does not export <BaseName>" -TestCases $privateFunctionFiles {
            param($BaseName)
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Not -Contain $expectedFunctionName
        }
    }

    Describe "Project structure" {
        It "has all the public functions as a file in 'PSIni/Public'" {
            $publicFunctions = (Get-Module -Name PSIni).ExportedFunctions.Keys

            foreach ($function in $publicFunctions) {
                (Get-ChildItem "$moduleRoot/Public").BaseName | Should -Contain $function
            }
        }
    }
}
