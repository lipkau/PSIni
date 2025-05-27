#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

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

        It "only accepts the values for -Encode which are supported by the powershell version" -Skip {
            # TODO: I don't know how to test this
        }

        It "provides autocompletion for parameters" -Skip {
            # TODO: I don't know how to test this
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
        }

        Describe "File I/O" {
            It "can append to an existing ini file" {
                Export-Ini @commonParameter -InputObject $defaultObject
                Export-Ini @commonParameter -InputObject $additionalObject -Append

                $fileContent = Get-Content -Path $testPath -Raw
                $fileContent | Should -Be ($defaultFileContent + $additionalFileContent)
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

            It "uses default behaviour for '-Force'" -Skip {
                # -Force is passed to Out-File
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
                $expectedFileContent = "[NoValues]${lf}Key1${lf}Key2${lf}"

                Export-Ini @commonParameter -InputObject $objectWithEmptyKeys -Format minified -SkipTrailingEqualSign
                $fileContent = Get-Content -Path $testPath -Raw

                $fileContent | Should -Be $expectedFileContent
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
        }
    }
}
