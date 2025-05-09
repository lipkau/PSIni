﻿#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Export-Ini" -Tag "Unit" {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        . (Join-Path $PSScriptRoot "./Helpers/Get-FileEncoding.ps1")

        $script:lf = if (($PSVersionTable.ContainsKey("Platform")) -and ($PSVersionTable.Platform -ne "Win32NT")) { "`n" }
        else { "`r`n" }
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name Export-Ini
        }

        It "exports an alias 'epini'" {
            Get-Alias -Definition Export-Ini | Where-Object { $_.name -eq "epini" } | Measure-Object | Select-Object -ExpandProperty Count | Should -HaveCount 1
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "Append"; type = "Switch" }
            @{ parameter = "CommentChar"; type = "String" }
            @{ parameter = "Encoding"; type = "String" }
            @{ parameter = "Force"; type = "Switch" }
            @{ parameter = "Format"; type = "String" }
            @{ parameter = "IgnoreComments"; type = "Switch" }
            @{ parameter = "InputObject"; type = "System.Collections.IDictionary" }
            @{ parameter = "Passthru"; type = "Switch" }
            @{ parameter = "Path"; type = "String" }
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
            $testPath = "TestDrive:\output$(Get-Random).ini"

            $script:commonParameter = @{
                Path        = $testPath
                ErrorAction = "Stop"
            }

            $defaultObject = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $defaultObject["_"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $defaultObject["_"]["KeyWithoutSection"] = "This is a key without section header"
            $defaultObject["Category1"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $defaultObject["Category1"]["Key1"] = "Value1"
            $defaultObject["Category1"]["Comment1"] = "Key2 = Value2"
            $defaultObject["Category2"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $defaultObject["Category2"]["Comment1"] = "Key1 = Value1"
            $defaultObject["Category2"]["Comment2"] = "Key2=Value2"

            $script:defaultFileContent = "KeyWithoutSection = This is a key without section header${lf}${lf}[Category1]${lf}Key1 = Value1${lf};Key2 = Value2${lf}${lf}[Category2]${lf};Key1 = Value1${lf};Key2=Value2${lf}${lf}"

            $additionalObject = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $additionalObject["Additional"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $additionalObject["Additional"]["Key1"] = "Value1"

            $script:additionalFileContent = "[Additional]${lf}Key1 = Value1${lf}${lf}"

            $objectWithEmptyKeys = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $objectWithEmptyKeys["NoValues"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $objectWithEmptyKeys["NoValues"]["Key1"] = $null
            $objectWithEmptyKeys["NoValues"]["Key2"] = ""
        }

        It "saves an object as ini file" {
            Export-Ini @commonParameter -InputObject $defaultObject
            $fileContent = Get-Content -Path $testPath -Raw

            $fileContent | Should -Be $defaultFileContent
        }

        It "accepts the InputObject via pipeline" {
            $defaultObject | Export-Ini @commonParameter
            Test-Path -Path $testPath | Should -Be $true
        }

        It "can append to an existing ini file" {
            Export-Ini @commonParameter -InputObject $defaultObject
            Export-Ini @commonParameter -InputObject $additionalObject -Append

            $fileContent = Get-Content -Path $testPath -Raw
            $fileContent | Should -Be ($defaultFileContent + $additionalFileContent)
        }

        It "it overwrite any existing file when using -Force" {
            Export-Ini @commonParameter -InputObject $defaultObject
            Get-Content -Path $testPath -Raw | Should -Not -Be $additionalFileContent

            Export-Ini @commonParameter -InputObject $additionalObject -Force
            Get-Content -Path $testPath -Raw | Should -Be $additionalFileContent
        }

        It "return the file object when using -Passthru" {
            $noReturn = Export-Ini @commonParameter -InputObject $defaultObject
            $passthru = Export-Ini @commonParameter -InputObject $defaultObject -Passthru

            $noReturn | Should -BeNullOrEmpty
            $passthru | Should -BeOfType [System.IO.FileSystemInfo]
        }

        It "writes an array as multiple keys with the same name" {
            $iniObject = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $iniObject["Section"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $iniObject["Section"]["ArrayKey"] = [System.Collections.ArrayList]::new()
            $null = $iniObject["Section"]["ArrayKey"].Add("Line 1")
            $null = $iniObject["Section"]["ArrayKey"].Add("Line 2")
            $null = $iniObject["Section"]["ArrayKey"].Add("Line 3")

            Export-Ini @commonParameter -InputObject $iniObject

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "[Section]${lf}ArrayKey = Line 1${lf}ArrayKey = Line 2${lf}ArrayKey = Line 3${lf}${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "write the ini file without comment when -IgnoreComments is defined" {
            Export-Ini @commonParameter -InputObject $defaultObject -IgnoreComments

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "KeyWithoutSection = This is a key without section header${lf}${lf}[Category1]${lf}Key1 = Value1${lf}${lf}[Category2]${lf}${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "uses the provided comment character" {
            Export-Ini @commonParameter -InputObject $defaultObject -CommentChar "#"

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "KeyWithoutSection = This is a key without section header${lf}${lf}[Category1]${lf}Key1 = Value1${lf}#Key2 = Value2${lf}${lf}[Category2]${lf}#Key1 = Value1${lf}#Key2=Value2${lf}${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "saves the ini file in 'minified' format" {
            Export-Ini @commonParameter -InputObject $defaultObject -Format "minified"

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "KeyWithoutSection=This is a key without section header${lf}[Category1]${lf}Key1=Value1${lf};Key2 = Value2${lf}[Category2]${lf};Key1 = Value1${lf};Key2=Value2${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "saves the ini file in 'pretty' format" {
            Export-Ini @commonParameter -InputObject $defaultObject -Format "pretty"

            $fileContent = Get-Content -Path $testPath -Raw

            $fileContent | Should -Be $defaultFileContent
        }

        It "uses the file encoding 'UTF8' if non is specified" {
            Export-Ini @commonParameter -InputObject $defaultObject

            if ($PSVersionTable.PSVersion.Major -ge 6) {
                (Get-FileEncoding -Path $testPath).Encoding | Should -Be "UTF8"
            }
            else {
                (Get-FileEncoding -Path $testPath).Encoding | Should -Be "UTF8-BOM"
            }
        }

        It "uses the file encoding provided when writing the ini file" {
            Export-Ini @commonParameter -InputObject $defaultObject -Encoding "utf32"

            (Get-FileEncoding -Path $testPath).Encoding | Should -Be "UTF32-LE"
        }

        It "writes out keys without a value" {
            Export-Ini @commonParameter -InputObject $objectWithEmptyKeys -Format minified

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "[NoValues]${lf}Key1=${lf}Key2=${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "writes out keys without trailing equal sign when no value is assigned" {
            Export-Ini @commonParameter -InputObject $objectWithEmptyKeys -Format minified -SkipTrailingEqualSign

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "[NoValues]${lf}Key1${lf}Key2${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "can write an empty section" {
            $iniObject = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $iniObject["EmptySection"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)

            Export-Ini @commonParameter -InputObject $iniObject

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "[EmptySection]${lf}${lf}"

            $fileContent | Should -Be $expectedFileContent
        }
    }
}
