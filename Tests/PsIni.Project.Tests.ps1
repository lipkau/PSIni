#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "General project validation" -Tag Unit {
    BeforeDiscovery {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $module = Get-Module PSIni
        $publicFunctionNames = @($module.ExportedFunctions.Keys)
        $script:publicFunctions = $publicFunctionNames | ForEach-Object { @{ BaseName = $_ } }
        $script:privateFunctions = $module.Invoke({ Get-Command -Module PSIni }).Name |
            Where-Object { $_ -notin $publicFunctionNames } |
            ForEach-Object { @{ BaseName = $_ } }
    }

    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        . "$PSScriptRoot/Helpers/Resolve-ProjectRoot.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:module = Get-Module PSIni
        $script:moduleRoot = Resolve-ProjectRoot
        $script:testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
    }

    Describe "Public functions" {

        It "has a test file for <BaseName>" -TestCases $publicFunctions {
            $expectedTestFile = "$BaseName.Unit.Tests.ps1"
            $testFiles.Name | Should -Contain $expectedTestFile
        }

        It "exports <BaseName>" -TestCases $publicFunctions {
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Contain $expectedFunctionName
        }
    }

    Describe "Private functions" {
        # TODO: have one test file for each private function
        <# It "has a test file for <BaseName>" -TestCases $privateFunctions {
                $expectedTestFile = "$BaseName.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            } #>

        It "does not export <BaseName>" -TestCases $privateFunctions {
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Not -Contain $expectedFunctionName
        }
    }

    Describe "Project structure" {
        It "has all the public functions as a file in 'PSIni/Public'" {
            $publicFunctions = (Get-Module -Name PSIni).ExportedFunctions.Keys

            foreach ($function in $publicFunctions) {
                (Get-ChildItem "$moduleRoot/PSIni/Public").BaseName | Should -Contain $function
            }
        }
    }
}
