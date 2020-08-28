#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

Describe "PsIni integration tests" -Tag "Integration" {
    BeforeAll {
        Remove-Module PsIni -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

        $dictIn = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        $dictIn["Category1"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        $dictIn["Category1"]["Key1"] = "Value1"
        $dictIn["Category1"]["Key2"] = "Value2"
        $dictIn["Category2"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        $dictIn["Category2"]["Key3"] = "Value3"
        $dictIn["Category2"]["Key4"] = "Value4"
    }
    BeforeEach {
        Export-Ini -InputObject $dictIn -Path "TestDrive:\output.ini" -Force -ErrorAction Stop
        $dictOut = Import-Ini -Path "TestDrive:\output.ini" -ErrorAction Stop
    }

    It "content matches original hashtable" {
        Compare-Object $dictIn $dictOut | Should -BeNullOrEmpty
    }
}
