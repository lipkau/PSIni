#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

Describe "ConvertTo-Ini" -Tag "Unit" {
    BeforeAll {
        Remove-Module PsIni -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop
    }

    Describe "Signature" {
        BeforeAll {
            $command = Get-Command -Name ConvertTo-Ini
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "InputObject"; type = "Object" }
        ) {
            param ($parameter, $type)
            $command | Should -HaveParameter $parameter -Type $type
        }
    }

    Describe "Behavior" {
        BeforeAll {
            $data = @"
{
    "awesome": "stuff",
    "key": 42,
    "section": {
        "subkey": "foo",
        "bar": 3.1415,
        "baz": "…"
    },
    "array": ["lorem", "ipsum", "dolor"],
    "section with array": {
        "array": ["lorem", "ipsum", "dolor"]
    },
    "prop": {
        "nestedProp": {
            "array": ["item"],
            "key": "string"
        }
    }
}
"@ | ConvertFrom-Json
        }

        It "does stuff" {
            $converted = ConvertTo-Ini $data
            $converted.Keys | Should -Contain "section with array"
            $converted.Keys | Should -Contain "section"
            $converted.Keys | Should -Contain "awesome"
            $converted.Keys | Should -Contain "key"
            $converted.Keys | Should -Contain "prop"
            $converted.Keys | Should -Contain "array"
        }

        It "aaa" {
            $converted = ConvertTo-Ini $data
            $converted["awesome"] | Should -Be "stuff"
            $converted["key"] | Should -Be "42"
        }

        It "bbb" {
            $converted = ConvertTo-Ini $data
            $converted["array"] | Should -Be @("lorem", "ipsum", "dolor")
        }

        It "bbb" {
            $converted = ConvertTo-Ini $data
            $converted["section"]["subkey"] | Should -Be "foo"
            $converted["section"]["bar"] | Should -Be "3.1415"
            $converted["section"]["baz"] | Should -Be "…"
        }

        It "bbb" {
            $converted = ConvertTo-Ini $data
            $converted["section with array"]["array"] | Should -Be @("lorem", "ipsum", "dolor")
        }

        It "bbb" {
            $converted = ConvertTo-Ini $data
            $converted["prop"]["nestedProp"] | Should -Be "@{array=item; key=string}"
        }
    }
}
