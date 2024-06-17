#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

Describe "ConvertFrom-Ini" -Tag "Unit" {
    BeforeAll {
        Remove-Module PsIni -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop
    }

    Describe "Signature" {
        BeforeAll {
            $command = Get-Command -Name ConvertFrom-Ini
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "InputObject"; type = "System.Collections.Specialized.OrderedDictionary" }
            @{ parameter = "Path"; type = "String[]" }
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

        It "can convert the content of an ini file to [PSCustomObject]" {
            ConvertFrom-Ini -Path $iniFile | Should -BeOfType [PSCustomObject]
        }

        It "can convert an OrderedDictionary to [PSCustomObject]" {
            $iniContent = Import-Ini -Path $iniFile
            ConvertFrom-Ini -InputObject $iniContent | Should -BeOfType [PSCustomObject]
        }

        It "accepts a path to an ini via pipeline" {
            $iniFile | ConvertFrom-Ini
        }

        It "accepts an OrderedDictionary via pipeline" {
            $iniContent = Import-Ini -Path $iniFile
            $iniContent | ConvertFrom-Ini
        }

        It "has the ini sections and keys without a section as root properties" {
            $convertedObject = ConvertFrom-Ini -Path $iniFile

            ($convertedObject | Get-Member -MemberType *Property).Name | Should -Be @("Arrays", "Comment1", "Key", "NoValues", "Strings")
        }

        It "treats the value of a key as string" {
            $convertedObject = ConvertFrom-Ini -Path $iniFile

            ($convertedObject.Strings | Get-Member -MemberType *Property).Name | Should -HaveCount 19
            $convertedObject.Strings.Key1 | Should -BeOfType [String]
        }

        It "treats multiple keys with the same name in the same section as an array" {
            $convertedObject = ConvertFrom-Ini -Path $iniFile

            , $convertedObject.Arrays.Array1 | Should -BeOfType [System.Collections.ArrayList]
            $convertedObject.Arrays.Array1 | Should -HaveCount 3
            $convertedObject.Arrays.Array1 | Should -Be @(@("1,2,3", "4,5,6", "7,8,9"))
        }
    }
}
