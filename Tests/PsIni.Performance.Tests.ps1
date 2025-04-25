#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Performance Tests" -Tag performance {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        . "$PSScriptRoot/Helpers/Get-AverageExecutionTime.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:dummyFile = "TestDrive:\dummy_$(Get-Random).ini"
        $script:bigIniFile = "$PSScriptRoot/large_sample.ini"
    }

    It "test file is larger than 2.5MB" {
        (Get-Item $bigIniFile).Length | Should -BeGreaterThan 2.5MB
        (Get-Item $bigIniFile).Length | Should -Be 2889891
    }

    Describe "Importing" {
        BeforeAll {
            $script:durationInMs = Get-AverageExecutionTime { Import-Ini $bigIniFile -ErrorAction Stop } -Count 10
        }

        It "processes a large INI file in less than <_> seconds" -TestCases @(
            10, 5, 3, 2.5 #, 2, 1
        ) {
            $durationInMs | Should -BeLessThan ($_ * 1000)
        }
    }

    Describe "Exporting" {
        BeforeAll {
            $iniContent = Import-Ini $bigIniFile -ErrorAction Stop
            $script:durationInMs = Get-AverageExecutionTime { $iniContent | Export-Ini -Path $dummyFile -ErrorAction Stop } -Count 10
        }

        It "exports a large INI file in less than <_> seconds" -TestCases @(
            10, 5, 3, 2.5 #, 2, 1
        ) {
            $durationInMs | Should -BeLessThan ($_ * 1000)
        }
    }
}
