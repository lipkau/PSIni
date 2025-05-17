#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "PSIni integration tests" -Tag "Integration" {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:dictIn = [ordered]@{
            "Category1" = [ordered]@{
                "Key1" = "Value1"
                "Key2" = "Value2"
            }
            "Category2" = [ordered]@{
                "Key3" = "Value3"
                "Key4" = "Value4"
            }
        }
    }
    BeforeEach {
        Export-Ini -InputObject $dictIn -Path "TestDrive:/output.ini" -ErrorAction Stop
        $script:dictOut = Import-Ini -Path "TestDrive:/output.ini" -ErrorAction Stop
    }

    It "content matches original hashtable" {
        Compare-Object $dictIn $dictOut | Should -BeNullOrEmpty
    }
}
