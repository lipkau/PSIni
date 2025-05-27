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
            Get-Alias -Definition Export-Ini |
                Where-Object { $_.name -eq "ipini" } |
                Measure-Object |
                Select-Object -ExpandProperty Count |
                Should -HaveCount 1
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "CommentChar"; type = "Char[]" }
            @{ parameter = "Encoding"; type = "System.Text.Encoding" }
            @{ parameter = "IgnoreComments"; type = "Switch" }
            @{ parameter = "IgnoreEmptySections"; type = "Switch" }
            @{ parameter = "InputString"; type = "String" }
            @{ parameter = "LiteralPath"; type = "String[]" }
            @{ parameter = "Path"; type = "String[]" }
        ) {
            param ($parameter, $type)
            $command | Should -HaveParameter $parameter -Type $type
        }

        It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
            @{ parameter = "CommentChar"; ; defaultValue = '@(";")' }
            @{ parameter = "Encoding"; defaultValue = "[System.Text.Encoding]::UTF8" }
        ) {
            $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
        }
    }

    Describe "Behaviors" {
        BeforeAll {
            $script:iniFile = Join-Path $PSScriptRoot "sample.ini"
            $script:dictOut = Import-Ini -Path $iniFile
        }

        Describe "Sections" {
            It "loads the sections as expected" {
                $dictOut.GetEnumerator().Name | Should -Be "_", "Strings", "Arrays", "NoValues", "EmptySection"
            }

            It "uses a module-wide variable for the keys that don't have a section" {
                InModuleScope PSIni { $script:NoSection = "NoName" }
                $dictNoNameSection = Import-Ini -Path $iniFile

                $dictNoNameSection.GetEnumerator().Name | Should -Be "NoName", "Strings", "Arrays", "NoValues", "EmptySection"
                $dictNoNameSection["NoName"]["Key"] | Should -Be "With No Section"
            }
        }

        Describe "Data types" {
            It "creates a OrderedDictionary from an INI file" {
                $dictOut | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

            It "keeps non repeating keys as [string]" {
                $dictOut["Strings"].GetEnumerator().Name | Should -HaveCount 21
                foreach ($key in $dictOut["Strings"].GetEnumerator().Name) {
                    $dictOut["Strings"][$key] | Should -BeOfType [String]
                }
            }

            It "duplicate keys in the same section are groups as an array" {
                $dictOut["Arrays"].GetEnumerator().Name | Should -HaveCount 2
                $dictOut["Arrays"]["String1"] | Should -BeOfType [String]
                # unary comma to avoid the pipeline
                , $dictOut["Arrays"]["Array1"] | Should -BeOfType [System.Collections.ArrayList]
                $dictOut["Arrays"]["Array1"] -join "," | Should -Be "1,2,3,4,5,6,7,8,9"
            }
        }

        Describe "Trim and Quotes" {
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
                $dictOut["Strings"][$key] | Should -Be $value
            }
        }

        Describe "Comments" {
            It "does not allow commentChar to be empty" {
                { Import-Ini -Path $iniFile -CommentChar "" } | Should -Throw
            }

            It "reads lines starting with ';' as comments by default" {
                $dictOut["Strings"].GetEnumerator().Name | Should -Contain "__Comment1"
                $dictOut["Strings"]["__Comment1"] | Should -Be "Key18 = Should be a comment"
            }

            It "allows for adding characters for comments" {
                $dictWithMoreComments = Import-Ini -Path $iniFile -CommentChar ";", "#"

                $dictWithMoreComments["Strings"]["__Comment1"] | Should -Be "Key18 = Should be a comment"
                $dictWithMoreComments["Strings"]["__Comment2"] | Should -Be "Key19 = This is only a comment if the commentChar is extended"
            }

            It "ignores comments when -IgnoreComments is provided" {
                $withComments = Import-Ini -Path $iniFile -CommentChar ";", "#"
                $withoutComments = Import-Ini -Path $iniFile -CommentChar ";", "#" -IgnoreComments

                $withComments["Strings"].GetEnumerator().Name | Should -HaveCount 21
                $withoutComments["Strings"].GetEnumerator().Name | Should -HaveCount 19
                $withComments["Strings"].GetEnumerator().Name | Should -Contain "__Comment1"
                $withoutComments["Strings"].GetEnumerator().Name | Should -Not -Contain "__Comment1"
            }

            It "can process a key named 'Comment'" {
                $dictOut["Strings"]["Comment"] | Should -Be "This is a key named Comment"
            }

            It "uses a module-wide variable for the comment identifier" {
                InModuleScope PSIni { $script:CommentPrefix = "..Comment" }
                $dictWithCustomComment = Import-Ini -Path $iniFile

                $dictWithCustomComment["Strings"].GetEnumerator().Name | Should -Contain "..Comment1"
                $dictWithCustomComment["Strings"]["..Comment1"] | Should -Be "Key18 = Should be a comment"
            }
        }

        Describe "Special Parameter" {
            It "ignores empty sections when -IgnoreEmptySections is provided" {
                $withEmptySections = Import-Ini -Path $iniFile
                $withoutEmptySections = Import-Ini -Path $iniFile -IgnoreEmptySections

                $withEmptySections.GetEnumerator().Name | Should -Contain "EmptySection"
                $withoutEmptySections.GetEnumerator().Name | Should -Not -Contain "EmptySection"
            }
        }

        Describe "Keys without a value" {
            It "stores keys without a value" {
                $dictOut["NoValues"]["Key1"] | Should -BeNullOrEmpty
            }

            It "stores keys without a value even when they don't have an `=` sign" {
                $dictOut["NoValues"]["Key2"] | Should -BeNullOrEmpty
            }

            It "stores keys without a value and trims surrounding whitespace" {
                $dictOut["NoValues"]["Key`3"] | Should -BeNullOrEmpty
            }
        }

        Describe "File I/O" {
            It "can read a list of files" {
                Import-Ini -Path $iniFile, $iniFile, $iniFile | Should -HaveCount 3
            }

            It "can read multiple files found with a wildcard" {
                $dictOut | Should -HaveCount 1

                $wildcardOut = Import-Ini -Path (Join-Path $PSScriptRoot "sample*.ini")
                $wildcardOut | Should -HaveCount 2
            }

            It "can handle a file with special characters in the name" {
                $dictSpecialFileName = Import-Ini -LiteralPath (Join-Path $PSScriptRoot "sample[].ini")

                $dictSpecialFileName["NoName"]["Key"] | Should -Be "Example"
            }

            It "can read multiple files with special characters in the name" {
                $file1 = Join-Path $PSScriptRoot "sample[].ini"
                $file2 = Join-Path $PSScriptRoot "sample.ini"

                $dictMultipleFiles = Import-Ini -LiteralPath $file1, $file2

                $dictMultipleFiles | Should -HaveCount 2
            }
        }

        Describe "Input from string" {
            It "Can process a string representation of a INI file" {
                $ini = "[section]`nkey=value"

                $dictFromString = Import-Ini -InputString $ini

                $dictFromString.GetEnumerator().Name | Should -Contain "section"
                $dictFromString["section"].GetEnumerator().Name | Should -Contain "key"
                $dictFromString["section"]["key"] | Should -Be "value"
            }
        }
    }
}
