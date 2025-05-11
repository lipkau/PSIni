#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "PSIni integration tests" -Tag "Integration" {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:tempFolder = [System.IO.Path]::GetTempPath()

        $dictIn = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        $dictIn["Category1"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        $dictIn["Category1"]["Key1"] = "Value1"
        $dictIn["Category1"]["Key2"] = "Value2"
        $dictIn["Category2"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        $dictIn["Category2"]["Key3"] = "Value3"
        $dictIn["Category2"]["Key4"] = "Value4"
    }
    BeforeEach {
        Export-Ini -InputObject $dictIn -Path "$tempFolder/output.ini" -Force -ErrorAction Stop
        $script:dictOut = Import-Ini -Path "$tempFolder/output.ini" -ErrorAction Stop
    }
    AfterAll {
        Remove-Item "$tempFolder/output.ini"
    }

    It "content matches original hashtable" {
        Compare-Object $dictIn $dictOut | Should -BeNullOrEmpty
    }
}
