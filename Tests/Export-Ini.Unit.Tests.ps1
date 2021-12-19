#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

Describe "Export-Ini" -Tag "Unit" {
    BeforeAll {
        Remove-Module PsIni -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force

        . (Join-Path $PSScriptRoot "./Helpers/Get-FileEncoding.ps1")

        $lf = if (($PSVersionTable.ContainsKey("Platform")) -and ($PSVersionTable.Platform -ne "Win32NT")) { "`n" }
        else { "`r`n" }
    }

    Describe "Signature" {
        BeforeAll {
            $command = Get-Command -Name Export-Ini
        }

        It "exports an alias 'epini'" {
            Get-Alias -Definition Export-Ini | Where-Object { $_.name -eq "epini" } | Measure-Object | Select-Object -ExpandProperty Count | Should -HaveCount 1
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "Append"; type = "Switch" }
            @{ parameter = "Encoding"; type = "String" }
            @{ parameter = "Path"; type = "String" }
            @{ parameter = "Force"; type = "Switch" }
            @{ parameter = "Format"; type = "String" }
            @{ parameter = "InputObject"; type = "System.Collections.IDictionary" }
            @{ parameter = "Passthru"; type = "Switch" }
            @{ parameter = "IgnoreComments"; type = "Switch" }
        ) {
            param ($parameter, $type)
            $command | Should -HaveParameter $parameter -Type $type
        }

        It "only accepts the values for -Encode which are supported by the powershell version" -Skip {
            # I don't know how to test this
        }

        It "provides autocompletion for parameters" -Skip {
            # I don't know how to test this
        }
    }

    Describe "Behavior" {
        BeforeEach {
            $testPath = "TestDrive:\output$(Get-Random).ini"

            $commonParameter = @{
                Path        = $testPath
                ErrorAction = "Stop"
            }

            $defaultObject = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $defaultObject["Category1"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $defaultObject["Category1"]["Key1"] = "Value1"
            $defaultObject["Category1"]["Comment1"] = "Key2 = Value2"
            $defaultObject["Category2"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $defaultObject["Category2"]["Comment1"] = "Key1 = Value1"
            $defaultObject["Category2"]["Comment2"] = "Key2 = Value2"

            $defaultFileContent = "[Category1]${lf}Key1 = Value1${lf};Key2 = Value2${lf}${lf}[Category2]${lf};Key1 = Value1${lf};Key2 = Value2${lf}"

            $additionalObject = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $additionalObject["Additional"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $additionalObject["Additional"]["Key1"] = "Value1"

            $additionalFileContent = "[Additional]${lf}Key1 = Value1${lf}"

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

        It "accepts the inputobject via pipeline" {
            $defaultObject | Export-Ini @commonParameter
            Test-Path -Path $testPath | Should -Be $true
        }

        It "can append to an existing ini file" {
            Export-Ini @commonParameter -InputObject $defaultObject
            Export-Ini @commonParameter -InputObject $additionalObject -Append

            $fileContent = Get-Content -Path $testPath -Raw
            $fileContent | Should -Be ($defaultFileContent + $additionalFileContent)
        }

        It "it overwrite any exisinting file when using -Force" {
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
            $expectedFileContent = "[Section]${lf}ArrayKey = Line 1${lf}ArrayKey = Line 2${lf}ArrayKey = Line 3${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "write the ini file without comment when -IgnoreComments is defined" {
            Export-Ini @commonParameter -InputObject $defaultObject -IgnoreComments

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "[Category1]${lf}Key1 = Value1${lf}${lf}[Category2]${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "saves the ini file in 'minified' format" {
            Export-Ini @commonParameter -InputObject $additionalObject -Format "minified"

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "[Additional]${lf}Key1=Value1${lf}"

            $fileContent | Should -Be $expectedFileContent
        }

        It "saves the ini file in 'pretty' format" {
            Export-Ini @commonParameter -InputObject $additionalObject -Format "pretty"

            $fileContent = Get-Content -Path $testPath -Raw
            $expectedFileContent = "[Additional]${lf}Key1 = Value1${lf}"

            $fileContent | Should -Be $expectedFileContent
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
    }
}
