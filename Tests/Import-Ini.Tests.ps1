Describe "Import-Ini" {

    BeforeAll {
        $iniFile = "TestDrive:\Settings.ini"

        Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop
    }
    BeforeEach {
        Set-Content -Path $iniFile -Force -Value @"
[Category1]
Key1 = Value1
Key2 = "Value2"
[Category2]
Key3 = Value3.1
Key3 = Value3.2
Key3 = Value3.3
Key4=Value4
"@
    }

    # assert
    Context "Alias" {
        It "Import-Ini alias should exist" {
            Get-Alias -Definition Import-Ini | Where-Object {$_.name -eq "ipi"} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
        }
    }

    Context "Functionality" {

        It "creates a OrderedDictionary from an INI file" {
            # act
            $dictOut = Import-Ini -Path $iniFile

            # assert
            $dictOut | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It "keeps non repeating keys as [string]" {
            # act
            $dictOut = Import-Ini -Path $iniFile

            #assert
            $dictOut["Category1"]["Key1"] | Should -BeOfType [String]
            $dictOut["Category1"]["Key2"] | Should -BeOfType [String]
            $dictOut["Category2"]["Key4"] | Should -BeOfType [String]
        }

        It "reads sames keys into an [array]" {
            # act
            $dictOut = Import-Ini -Path $iniFile

            #assert
            # unary comma to avoid the pipeline
            , $dictOut["Category2"]["Key3"] | Should -BeOfType [System.Collections.ArrayList]
        }

        It "can read a list of files" {
            #act
            $dictOut = Import-Ini -Path $iniFile, $iniFile, $iniFile

            #assert
            $dictOut | Should -HaveCount 3
        }

        It "uses the correct values" {
            #act
            $dictOut = Import-Ini -Path $iniFile

            #assert
            $dictOut["Category1"]["Key1"] | Should -Be "Value1"
            $dictOut["Category1"]["Key2"] | Should -Be "Value2"
            $dictOut["Category2"]["Key3"] | Should -Be @("Value3.1", "Value3.2", "Value3.3")
            $dictOut["Category2"]["Key4"] | Should -Be "Value4"
        }

        It "reads lines starting wit ';' as comments by default" {
            #arrange
            Add-Content -Path $iniFile -Value ";comment line"
            Add-Content -Path $iniFile -Value "; comment line"

            #act
            $dictOut = Import-Ini -Path $iniFile

            #assert
            $dictOut["Category2"].Keys | Should -Contain "Comment1"
            $dictOut["Category2"]["Comment1"] | Should -Be ";comment line"
            $dictOut["Category2"]["Comment2"] | Should -Be "; comment line"
        }

        It "allows for custom comment chars, such as <commentChar>" -TestCases @(
            @{ commentChar = "#" }
            @{ commentChar = ";" }
            @{ commentChar = "=" }
        ) {
            param($commentChar)

            #arrange
            Add-Content -Path $iniFile -Value "$commentChar comment line"

            #act
            $dictOut = Import-Ini -Path $iniFile -CommentChar $commentChar

            #assert
            $dictOut["Category2"]["Comment1"] | Should -Be "$commentChar comment line"
        }

        It "allows for a list of custom comment chars, such as <commentChar>" -TestCases @(
            @{ commentChar = "#;" }
            @{ commentChar = ".;" }
        ) {
            param([char[]]$commentChar)

            #arrange
            foreach ($char in $commentChar) {
                Add-Content -Path $iniFile -Value "$char comment line"
            }

            #act
            $dictOut = Import-Ini -Path $iniFile -CommentChar $commentChar

            #assert
            $index = 1
            foreach ($char in $commentChar) {
                $dictOut["Category2"]["Comment$index"] | Should -Be "$char comment line"
                $index++
            }
        }

        It "ignores comments when -IgnoreComments is provided" {
            #arrange
            Add-Content -Path $iniFile -Value "# comment line"

            #act
            $dictOut = Import-Ini -Path $iniFile -IgnoreComments

            #assert
            $dictOut["Category1"].Keys | Should -Not -Contain "Comment1"
            $dictOut["Category2"].Keys | Should -Not -Contain "Comment1"
        }
    }
}
