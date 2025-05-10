#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Import-Ini" -Tag "Unit" {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name Import-Ini
        }

        It "exports an alias 'ipini'" {
            Get-Alias -Definition Export-Ini | Where-Object { $_.name -eq "ipini" } | Measure-Object | Select-Object -ExpandProperty Count | Should -HaveCount 1
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "Path"; type = "String[]" }
            @{ parameter = "LiteralPath"; type = "String[]" }
            @{ parameter = "CommentChar"; type = "Char[]" }
            @{ parameter = "IgnoreComments"; type = "Switch" }
            @{ parameter = "IgnoreEmptySections"; type = "Switch" }
        ) {
            param ($parameter, $type)
            $command | Should -HaveParameter $parameter -Type $type
        }

        It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
            @{ parameter = "CommentChar"; ; defaultValue = '@(";")' }
        ) {
            $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
        }
    }

    Describe "Behaviors" {
        BeforeAll {
            $script:iniFile = Join-Path $PSScriptRoot "sample.ini"
        }

        It "creates a OrderedDictionary from an INI file" {
            Import-Ini -Path $iniFile | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It "loads the sections as expected" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut.Keys | Should -Be "_", "Strings", "Arrays", "NoValues", "EmptySection"
        }

        It "uses a module-wide variable for the keys that don't have a section" {
            InModuleScope PSIni { $script:NoSection = "NoName" }
            $dictOut = Import-Ini -Path $iniFile

            $dictOut.Keys | Should -Be "NoName", "Strings", "Arrays", "NoValues", "EmptySection"
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

        It "ignores leading and trailing whitespaces from the key and the value" -TestCases @(
            @{ key = "Key1"; value = "Value1" }
            @{ key = "Key2"; value = "Value2" }
            @{ key = "Key3"; value = "Value3" }
            @{ key = "Key4"; value = "Value4" }
            @{ key = "Key5"; value = "Value5" }
            @{ key = "Key6"; value = "Value6" }
            @{ key = "Key7"; value = "Value7" }
            @{ key = "Key8"; value = "Value8" }
            @{ key = "Key9"; value = "Value9" }
        ) {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["Strings"][$key] | Should -Be $value
        }

        It "preserves quotes in the values" -TestCases @(
            @{ key = "Key10"; value = "`"Value10`"" }
            @{ key = "Key11"; value = "`"`"Value11`"`"" }
            @{ key = "Key12"; value = "'Value12'" }
            @{ key = "Key13"; value = "`"'Value13'`"" }
            @{ key = "Key14"; value = "'`"Value14`"'" }
            @{ key = "Key15"; value = "`"  Value15  `"" }
            @{ key = "Key16"; value = "`"  '  Value16  '  `"" }
            @{ key = "Key17"; value = "Value`"17`"" }
        ) {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["Strings"][$key] | Should -Be $value
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

        It "ignores empty sections when -IgnoreEmptySections is provided" {
            $withEmptySections = Import-Ini -Path $iniFile
            $withoutEmptySections = Import-Ini -Path $iniFile -IgnoreEmptySections

            $withEmptySections.Keys | Should -Contain "EmptySection"
            $withoutEmptySections.Keys | Should -Not -Contain "EmptySection"
        }

        It "stores keys without a value" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["NoValues"]["Key1"] | Should -BeNullOrEmpty
        }

        It "stores keys without a value even when they don't have an `=` sign" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["NoValues"]["Key2"] | Should -BeNullOrEmpty
        }

        It "stores keys without a value and trims surrounding whitespace" {
            $dictOut = Import-Ini -Path $iniFile

            $dictOut["NoValues"]["Key`3"] | Should -BeNullOrEmpty
        }

        It "can read multiple files found with a wildcard" {
            $wildcardPath = Join-Path $PSScriptRoot "sample*.ini"

            $dictOut = Import-Ini -Path $iniFile
            $dictOut | Should -HaveCount 1

            $wildcardOut = Import-Ini -Path $wildcardPath
            $wildcardOut | Should -HaveCount 2
        }

        It "can handle a file with special characters in the name" {
            $specialPath = Join-Path $PSScriptRoot "sample[].ini"

            $dictOut = Import-Ini -LiteralPath $specialPath

            $dictOut["NoName"]["Key"] | Should -Be "Example"
        }

        It "can read multiple files with special characters in the name" {
            $file1 = Join-Path $PSScriptRoot "sample[].ini"
            $file2 = Join-Path $PSScriptRoot "sample.ini"

            $dictOut = Import-Ini -LiteralPath $file1, $file2

            $dictOut | Should -HaveCount 2
        }
    }
}
