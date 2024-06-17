#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

Describe "Import-Ini" -Tag "Unit" {
    BeforeAll {
        Remove-Module PsIni -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop
    }

    Describe "Signature" {
        BeforeAll {
            $command = Get-Command -Name Import-Ini
        }

        It "exports an alias 'ipini'" {
            Get-Alias -Definition Export-Ini | Where-Object { $_.name -eq "ipini" } | Measure-Object | Select-Object -ExpandProperty Count | Should -HaveCount 1
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "Path"; type = "String[]" }
            @{ parameter = "CommentChar"; type = "Char[]" }
            @{ parameter = "IgnoreComments"; type = "Switch" }
        ) {
            param ($parameter, $type)
            $command | Should -HaveParameter $parameter -Type $type
        }
    }

    Describe "Behavior" {
        BeforeAll {
            $iniFile = Join-Path $PSScriptRoot "sample.ini"
        }
        BeforeEach {
            Remove-Module PsIni -ErrorAction SilentlyContinue
            Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop
        }

        It "creates a OrderedDictionary from an INI file" {
            Import-Ini -Path $iniFile | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It "loads the sections as expected" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut.Keys | Should -Be "_", "Strings", "Arrays", "NoValues"
        }

        It "uses a module-wide variable for the keys that don't have a section" {
            InModuleScope PsIni { $script:NoSection = "NoName" }
            $dictOut = Import-Ini -Path $iniFile

            $dictOut.Keys | Should -Be "NoName", "Strings", "Arrays", "NoValues"
            $dictOut["NoName"]["Key"] | Should -Be "With No Section"
        }

        It "keeps non repeating keys as [string]" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["Strings"].Keys | Should -HaveCount 19
            foreach ($key in $dictOut["Strings"].Keys) {
                $dictOut["Strings"][$key] | Should -BeOfType [String]
            }
        }

        It "duplicate keys in the same section are groups as an array" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["Arrays"].Keys | Should -HaveCount 2
            $dictOut["Arrays"]["String1"] | Should -BeOfType [String]
            # unary comma to avoid the pipeline
            , $dictOut["Arrays"]["Array1"] | Should -BeOfType [System.Collections.ArrayList]
            $dictOut["Arrays"]["Array1"] -join "," | Should -Be "1,2,3,4,5,6,7,8,9"
        }

        It "can read a list of files" {
            Import-Ini -Path $iniFile, $iniFile, $iniFile | Should -HaveCount 3
        }

        It "ignores leading and trailing whitespaces from the key and the value" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["Strings"]["Key1"] | Should -Be "Value1"
            $dictOut["Strings"]["Key2"] | Should -Be "Value2"
            $dictOut["Strings"]["Key3"] | Should -Be "Value3"
            $dictOut["Strings"]["Key4"] | Should -Be "Value4"
            $dictOut["Strings"]["Key5"] | Should -Be "Value5"
            $dictOut["Strings"]["Key6"] | Should -Be "Value6"
            $dictOut["Strings"]["Key7"] | Should -Be "Value7"
            $dictOut["Strings"]["Key8"] | Should -Be "Value8"
            $dictOut["Strings"]["Key9"] | Should -Be "Value9"
        }

        It "handles quotes in the values as expected" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["Strings"]["Key1"] | Should -Be "Value1"
            $dictOut["Strings"]["Key10"] | Should -Be "Value10"
            $dictOut["Strings"]["Key11"] | Should -Be "`"Value11`""
            $dictOut["Strings"]["Key12"] | Should -Be "Value12"
            $dictOut["Strings"]["Key13"] | Should -Be "'Value13'"
            $dictOut["Strings"]["Key14"] | Should -Be "`"Value14`""
            $dictOut["Strings"]["Key15"] | Should -Be "Value15"
            $dictOut["Strings"]["Key16"] | Should -Be "'  Value16  '"
            $dictOut["Strings"]["Key17"] | Should -Be "Value`"17`""
        }

        It "reads lines starting with ';' as comments by default" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["Strings"].Keys | Should -Contain "Comment1"
            $dictOut["Strings"]["Comment1"] | Should -Be "Key18 = Should be a comment"
            $dictOut["Strings"]["#Key19"] | Should -Be "This is only a comment if the commentChar is extended"
        }

        It "allows for adding characters for comments" {
            $dictOut = Import-Ini -Path $iniFile -CommentChar ";", "#"

            $dictOut["Strings"]["Comment1"] | Should -Be "Key18 = Should be a comment"
            $dictOut["Strings"]["Comment2"] | Should -Be "Key19 = This is only a comment if the commentChar is extended"
        }

        It "ignores comments when -IgnoreComments is provided" {
            $withComments = Import-Ini -Path $iniFile -CommentChar ";", "#"
            $withoutComments = Import-Ini -Path $iniFile -CommentChar ";", "#" -IgnoreComments

            $withComments["Strings"].Keys | Should -HaveCount 19
            $withoutComments["Strings"].Keys | Should -HaveCount 17
            $withComments["Strings"].Keys | Should -Contain "Comment1"
            $withoutComments["Strings"].Keys | Should -Not -Contain "Comment1"
        }

        It "stores keys without a value" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["NoValues"]["Key1"] | Should -BeNullOrEmpty
        }

        It "stores keys without a value even when they don't have an `=` sign" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["NoValues"]["Key2"] | Should -BeNullOrEmpty
        }
    }
}
