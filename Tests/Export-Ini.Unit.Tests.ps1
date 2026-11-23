#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

Describe "Export-Ini" -Tag "Unit" {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Get-FileEncoding.ps1"
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        # Adjust for the correct line ending based on the system running the tests
        $script:lf = if (($PSVersionTable.ContainsKey("Platform")) -and ($PSVersionTable.Platform -ne "Win32NT")) { "`n" }
        else { "`r`n" }
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name Export-Ini
        }

        It "exports an alias 'epini'" {
            Get-Alias -Definition Export-Ini |
                Where-Object { $_.name -eq "epini" } |
                Measure-Object |
                Select-Object -ExpandProperty Count |
                Should -HaveCount 1
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "Append"; type = "Switch" }
            @{ parameter = "CommentChar"; type = "String" }
            @{ parameter = "Encoding"; type = "String" }
            @{ parameter = "FilePath"; type = "String" }
            @{ parameter = "Force"; type = "Switch" }
            @{ parameter = "Format"; type = "String" }
            @{ parameter = "IgnoreComments"; type = "Switch" }
            @{ parameter = "InputObject"; type = "System.Collections.IDictionary" }
            @{ parameter = "LiteralPath"; type = "String" }
            @{ parameter = "NoClobber"; type = "Switch" }
        ) {
            $command | Should -HaveParameter $parameter -Type $type
        }

        It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
            @{ parameter = "CommentChar"; ; defaultValue = ";" }
            @{ parameter = "Encoding"; ; defaultValue = "UTF8" }
            @{ parameter = "Format"; ; defaultValue = "pretty" }
        ) {
            $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
        }

        Context "-Encoding" {
            BeforeAll {
                $outFile = Get-Command -Name Out-File -Module Microsoft.PowerShell.Utility -CommandType Cmdlet
                $script:builtInEncodings = if ($PSVersionTable.PSVersion.Major -ge 6) {
                    (
                        $outFile.Parameters['Encoding'].Attributes |
                            Where-Object { $_ -is [ArgumentCompletions] }
                    )[0].CompleteArgument('Out-File', 'Encoding', '*', $null, @{ }).CompletionText
                }
                else {
                    (
                        $outFile.Parameters['Encoding'].Attributes |
                            Where-Object { $_.TypeId -eq [ValidateSet] }
                    )[0].ValidValues
                }

                function Get-EncodingCompletion {
                    param([String] $Word)

                    $line = "Export-Ini -Encoding $Word"
                    (TabExpansion2 -inputScript $line -cursorColumn $line.Length).CompletionMatches.CompletionText
                }
            }

            AfterEach {
                Remove-Item -Path Function:\Out-File -ErrorAction SilentlyContinue
            }

            It "only accepts the values for -Encoding which are supported by the powershell version" {
                $builtInEncodings | Should -Not -BeNullOrEmpty

                foreach ($encoding in $builtInEncodings) {
                    { Export-Ini -InputObject @{} -Path "TestDrive:\encoding.ini" -Encoding $encoding -Force -ErrorAction Stop } |
                        Should -Not -Throw
                }
                { Export-Ini -InputObject @{} -Path "TestDrive:\encoding.ini" -Encoding "NotAnEncoding" } |
                    Should -Throw "*Encoding*"
            }

            It "uses the built-in Out-File even when another 'Out-File' command exists" {
                function global:Out-File {
                    param(
                        [ValidateSet("NotAnEncoding")]
                        $Encoding
                    )
                    throw "The overridden Out-File was called"
                }

                $path = "TestDrive:\override$(Get-Random).ini"
                { Export-Ini -InputObject @{ Section = @{ Key = "Value" } } -Path $path -Encoding "utf8" -ErrorAction Stop } |
                    Should -Not -Throw
                $path | Should -Exist
                Get-EncodingCompletion -Word "" | Should -Not -Contain "NotAnEncoding"
            }

            It "completes '<word>' to matching encodings" -TestCases @(
                @{ word = "a"; expected = "ascii" }
                @{ word = "u"; expected = "utf8" }
                @{ word = "UTF3"; expected = "utf32" }
            ) {
                $completions = Get-EncodingCompletion -Word $word

                $completions | Should -Contain $expected
                $completions | ForEach-Object { $_ | Should -BeLike "$word*" }
            }

            It "completes an empty word to all supported encodings" {
                $completions = Get-EncodingCompletion -Word ""

                $completions | Should -HaveCount @($builtInEncodings).Count
            }
        }
    }

    Describe "Behaviors" {
        BeforeEach {
            $script:testPath = "TestDrive:\output$(Get-Random).ini"

            $script:commonParameter = @{
                Path        = $testPath
                ErrorAction = "Stop"
            }

            $script:defaultObject = [ordered]@{
                "_"         = [ordered]@{
                    "KeyWithoutSection" = "This is a key without section header"
                }
                "Category1" = [ordered]@{
                    "Keys"       = 'This is a special case because it breaks code like "$InputObject.Keys"'
                    "Key1"       = "Value1"
                    "__Comment1" = "Key2 = Value2"
                }
                "Category2" = [ordered]@{
                    "__Comment1" = "Key1 = Value1"
                    "__Comment2" = "Key2=Value2"
                }
            }

            $script:defaultFileContent = "KeyWithoutSection = This is a key without section header${lf}${lf}[Category1]${lf}Keys = This is a special case because it breaks code like `"`$InputObject.Keys`"${lf}Key1 = Value1${lf};Key2 = Value2${lf}${lf}[Category2]${lf};Key1 = Value1${lf};Key2=Value2${lf}${lf}"

            $script:additionalObject = [ordered]@{
                "Additional" = [ordered]@{ "Key1" = "Value1" }
            }

            $script:additionalFileContent = "[Additional]${lf}Key1 = Value1${lf}${lf}"

            $script:objectWithEmptyKeys = [ordered]@{
                "NoValues" = [ordered]@{ "Key1" = $null; "Key2" = ""
                }
            }
        }

        Describe "Input" {
            It "saves an object as ini file" {
                Export-Ini @commonParameter -InputObject $defaultObject
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $defaultFileContent
            }

            It "accepts the InputObject via pipeline" {
                $defaultObject | Export-Ini @commonParameter
                Test-Path -Path $testPath | Should -Be $true
            }

            It "writes every object from the pipeline to the file" {
                $additionalObject | Export-Ini @commonParameter
                $defaultObject, $additionalObject | Export-Ini @commonParameter

                $fileContent = Get-Content -Path $testPath -Raw
                $fileContent | Should -Be ($defaultFileContent + $additionalFileContent)
            }

            It "does not write any object from the pipeline to an existing file when '-NoClobber' is defined" {
                Export-Ini @commonParameter -InputObject $additionalObject

                { $defaultObject, $additionalObject | Export-Ini @commonParameter -NoClobber } | Should -Throw
                Get-Content -Path $testPath -Raw | Should -Be $additionalFileContent
            }
        }

        Describe "File I/O" {
            It "can append to an existing ini file" {
                Export-Ini @commonParameter -InputObject $defaultObject
                Export-Ini @commonParameter -InputObject $additionalObject -Append

                $fileContent = Get-Content -Path $testPath -Raw
                $fileContent | Should -Be ($defaultFileContent + $additionalFileContent)
            }

            It "warns when appending keys without a section to a file with sections" {
                Export-Ini @commonParameter -InputObject $additionalObject
                Export-Ini @commonParameter -InputObject @{ "Key" = "Value" } -Append -WarningVariable warning -WarningAction SilentlyContinue

                $warning | Should -HaveCount 1
                $warning[0] | Should -BeLike "*keys without a section*"
            }

            It "does not warn when appending keys without a section to a file without sections" {
                Export-Ini @commonParameter -InputObject @{ "Key1" = "Value1" }
                Export-Ini @commonParameter -InputObject @{ "Key2" = "Value2" } -Append -WarningVariable warning -WarningAction SilentlyContinue

                $warning | Should -BeNullOrEmpty
                Get-Content -Path $testPath -Raw | Should -Be "Key1 = Value1${lf}${lf}Key2 = Value2${lf}${lf}"
            }

            It "it overwrite any existing by default" {
                Export-Ini @commonParameter -InputObject $defaultObject
                Get-Content -Path $testPath -Raw | Should -Not -Be $additionalFileContent

                Export-Ini @commonParameter -InputObject $additionalObject
                Get-Content -Path $testPath -Raw | Should -Be $additionalFileContent
            }

            It "does not overwrite an existing file when '-NoClobber' is defined" {
                Export-Ini @commonParameter -InputObject $defaultObject
                { Export-Ini @commonParameter -InputObject $additionalObject -NoClobber } | Should -Throw
            }

            It "can write a file name with special characters" {
                $specialFileName = $testPath -replace "output", "special[file]name"

                Export-Ini -InputObject $defaultObject -LiteralPath $specialFileName -ErrorAction "Stop"
                $fileContent = Get-Content -LiteralPath $specialFileName -Raw

                $fileContent | Should -Be $defaultFileContent
            }
        }

        Describe "Special Parameter" {
            It "write the ini file without comment when '-IgnoreComments' is defined" {
                $expectedFileContent = "KeyWithoutSection = This is a key without section header${lf}${lf}[Category1]${lf}Keys = This is a special case because it breaks code like `"`$InputObject.Keys`"${lf}Key1 = Value1${lf}${lf}[Category2]${lf}${lf}"

                Export-Ini @commonParameter -InputObject $defaultObject -IgnoreComments
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
            }

            It "uses the provided '-CommentChar' character" {
                $expectedFileContent = "KeyWithoutSection = This is a key without section header${lf}${lf}[Category1]${lf}Keys = This is a special case because it breaks code like `"`$InputObject.Keys`"${lf}Key1 = Value1${lf}#Key2 = Value2${lf}${lf}[Category2]${lf}#Key1 = Value1${lf}#Key2=Value2${lf}${lf}"

                Export-Ini @commonParameter -InputObject $defaultObject -CommentChar "#"
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
            }

            It "saves the ini file minified with '-Format minified'" {
                $expectedFileContent = "KeyWithoutSection=This is a key without section header${lf}[Category1]${lf}Keys=This is a special case because it breaks code like `"`$InputObject.Keys`"${lf}Key1=Value1${lf};Key2 = Value2${lf}[Category2]${lf};Key1 = Value1${lf};Key2=Value2${lf}"

                Export-Ini @commonParameter -InputObject $defaultObject -Format "minified"
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
            }

            It "saves the ini file formatted with '-Format pretty'" {
                Export-Ini @commonParameter -InputObject $defaultObject -Format "pretty"

                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $defaultFileContent
            }

            It "uses 'UTF8' encoding if non is specified" {
                Export-Ini @commonParameter -InputObject $defaultObject

                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    (Get-FileEncoding -Path $testPath).Encoding | Should -Be "UTF8"
                }
                else {
                    (Get-FileEncoding -Path $testPath).Encoding | Should -Be "UTF8-BOM"
                }
            }

            It "uses the file encoding provided with '-Encoding'" {
                Export-Ini @commonParameter -InputObject $defaultObject -Encoding "utf32"

                (Get-FileEncoding -Path $testPath).Encoding | Should -Be "UTF32-LE"
            }

            It "overwrites a read-only file only when '-Force' is defined" {
                Export-Ini @commonParameter -InputObject $defaultObject
                $file = Get-Item -Path $testPath
                $file.IsReadOnly = $true

                try {
                    { Export-Ini @commonParameter -InputObject $additionalObject } | Should -Throw
                    Get-Content -Path $testPath -Raw | Should -Be $defaultFileContent

                    Export-Ini @commonParameter -InputObject $additionalObject -Force
                    Get-Content -Path $testPath -Raw | Should -Be $additionalFileContent
                }
                finally {
                    $file.Refresh()
                    $file.IsReadOnly = $false
                }
            }
        }

        Describe "Arrays" {
            It "writes an array as multiple keys with the same name" {
                $iniObject = [ordered]@{
                    "Section" = [ordered]@{ "ArrayKey" = [System.Collections.ArrayList]::new() }
                }
                $null = $iniObject["Section"]["ArrayKey"].Add("Line 1")
                $null = $iniObject["Section"]["ArrayKey"].Add("Line 2")
                $null = $iniObject["Section"]["ArrayKey"].Add("Line 3")

                $expectedFileContent = "[Section]${lf}ArrayKey = Line 1${lf}ArrayKey = Line 2${lf}ArrayKey = Line 3${lf}${lf}"

                Export-Ini @commonParameter -InputObject $iniObject
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
            }
        }

        Describe "Keys and values" {
            It "writes out keys without a value" {
                $expectedFileContent = "[NoValues]${lf}Key1=${lf}Key2=${lf}"

                Export-Ini @commonParameter -InputObject $objectWithEmptyKeys -Format minified
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
            }

            It "writes out keys without trailing equal sign when no value is assigned" {
                $expectedFileContent = "[NoValues]${lf}Key1${lf}Key2=${lf}"

                Export-Ini @commonParameter -InputObject $objectWithEmptyKeys -Format minified -SkipTrailingEqualSign
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
            }

            It "writes the value '<value>' as '<expected>'" -TestCases @(
                @{ value = 0; expected = "Key=0" }
                @{ value = $false; expected = "Key=False" }
                @{ value = ""; expected = "Key=" }
                @{ value = $null; expected = "Key=" }
            ) {
                $iniObject = [ordered]@{ "Section" = [ordered]@{ "Key" = $value } }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "[Section]${lf}${expected}${lf}"
            }

            It "writes the value '<value>' as '<expected>' when '-SkipTrailingEqualSign' is defined" -TestCases @(
                @{ value = 0; expected = "Key=0" }
                @{ value = $false; expected = "Key=False" }
                @{ value = ""; expected = "Key=" }
                @{ value = $null; expected = "Key" }
            ) {
                $iniObject = [ordered]@{ "Section" = [ordered]@{ "Key" = $value } }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified -SkipTrailingEqualSign
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "[Section]${lf}${expected}${lf}"
            }

            It "writes every entry of an array that contains an empty string" {
                $iniObject = [ordered]@{ "Section" = [ordered]@{ "Key" = @("Value", "", 0) } }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified -SkipTrailingEqualSign
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "[Section]${lf}Key=Value${lf}Key=${lf}Key=0${lf}"
            }

            It "writes a key that only starts with '__Comment' as a key" {
                $iniObject = [ordered]@{ "Section" = [ordered]@{ "__Commentary" = "Value"; "__Comment1" = "a comment" } }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified -IgnoreComments
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "[Section]${lf}__Commentary=Value${lf}"
            }

            It "writes a key with an empty array as a key without a value" {
                $iniObject = [ordered]@{ "Section" = [ordered]@{ "Key" = @() } }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified -SkipTrailingEqualSign
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "[Section]${lf}Key${lf}"
            }
        }

        Describe "Sections" {
            It "can write an empty section" {
                $iniObject = [ordered]@{ "EmptySection" = [ordered]@{} }
                $expectedFileContent = "[EmptySection]${lf}${lf}"

                Export-Ini @commonParameter -InputObject $iniObject
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
            }

            It "writes nested input as sections with keys" {
                $iniObject = [ordered]@{
                    "Section1" = [ordered]@{ "Key1" = "Value1"; "Key2" = "Value2" }
                    "Section2" = @{ "Key1" = "Value1" }
                }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "[Section1]${lf}Key1=Value1${lf}Key2=Value2${lf}[Section2]${lf}Key1=Value1${lf}"
            }
        }

        Describe "Keys without a section" {
            It "writes a flat hashtable as keys without a section" {
                Export-Ini @commonParameter -InputObject @{ "Key" = "Value" }
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "Key = Value${lf}${lf}"
            }

            It "writes every kind of value of a flat dictionary" {
                $iniObject = [ordered]@{
                    "Key1"       = "Value1"
                    "Empty"      = $null
                    "Zero"       = 0
                    "Array"      = @("Line 1", "Line 2")
                    "__Comment1" = "a comment"
                }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "Key1=Value1${lf}Empty=${lf}Zero=0${lf}Array=Line 1${lf}Array=Line 2${lf};a comment${lf}"
            }

            It "writes keys without a section before the first section of mixed input" {
                $iniObject = [ordered]@{
                    "Section1" = [ordered]@{ "Key1" = "Value1" }
                    "Key1"     = "Value1"
                    "Section2" = [ordered]@{ "Key2" = "Value2" }
                    "Key2"     = "Value2"
                }

                Export-Ini @commonParameter -InputObject $iniObject
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "Key1 = Value1${lf}Key2 = Value2${lf}${lf}[Section1]${lf}Key1 = Value1${lf}${lf}[Section2]${lf}Key2 = Value2${lf}${lf}"
            }

            It "writes the keys of the '_' section and other keys without a section together" {
                $iniObject = [ordered]@{
                    "Section" = [ordered]@{ "Key1" = "Value1" }
                    "_"       = [ordered]@{ "Key2" = "Value2" }
                    "Key3"    = "Value3"
                }

                Export-Ini @commonParameter -InputObject $iniObject -Format minified
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be "Key2=Value2${lf}Key3=Value3${lf}[Section]${lf}Key1=Value1${lf}"
            }

            It "keeps the keys of <name> input when the file is read with Import-Ini" -TestCases @(
                @{
                    name      = "flat"
                    iniObject = [ordered]@{ "Key1" = "Value1"; "Key2" = "Value2" }
                    expected  = [ordered]@{ "_" = [ordered]@{ "Key1" = "Value1"; "Key2" = "Value2" } }
                }
                @{
                    name      = "mixed"
                    iniObject = [ordered]@{ "Section" = [ordered]@{ "Key1" = "Value1" }; "Key2" = "Value2" }
                    expected  = [ordered]@{ "_" = [ordered]@{ "Key2" = "Value2" }; "Section" = [ordered]@{ "Key1" = "Value1" } }
                }
                @{
                    name      = "nested"
                    iniObject = [ordered]@{ "Section1" = [ordered]@{ "Key1" = "Value1" }; "Section2" = [ordered]@{ "Key2" = "Value2" } }
                    expected  = [ordered]@{ "Section1" = [ordered]@{ "Key1" = "Value1" }; "Section2" = [ordered]@{ "Key2" = "Value2" } }
                }
            ) {
                Export-Ini @commonParameter -InputObject $iniObject
                $result = Import-Ini -Path $testPath

                @($result.Keys) | Should -Be @($expected.Keys)
                foreach ($section in $expected.Keys) {
                    @($result[$section].Keys) | Should -Be @($expected[$section].Keys)
                    foreach ($key in $expected[$section].Keys) {
                        $result[$section][$key] | Should -Be $expected[$section][$key]
                    }
                }
            }
        }
    }
}
