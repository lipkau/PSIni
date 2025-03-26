#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "ConvertTo-Ini" -Tag "Unit" {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name ConvertTo-Ini
        }

        It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
            @{ parameter = "InputObject"; type = "Object" }
        ) {
            param ($parameter, $type)
            $command | Should -HaveParameter $parameter -Type $type
        }
    }

    Describe "Behaviors" {
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

            $script:converted = ConvertTo-Ini $data -WarningAction Ignore
        }

        It "gets the keys of the input object" {
            $converted.Keys | Should -Contain "section with array"
            $converted.Keys | Should -Contain "section"
            $converted.Keys | Should -Contain "awesome"
            $converted.Keys | Should -Contain "key"
            $converted.Keys | Should -Contain "prop"
            $converted.Keys | Should -Contain "array"
        }

        It "gets sets the values of the input object" {
            $converted["awesome"] | Should -Be "stuff"
            $converted["key"] | Should -Be "42"
        }

        It "processes arrays" {
            $converted["array"] | Should -Be @("lorem", "ipsum", "dolor")
        }

        It "processes nested objects" {
            $converted["section"]["subkey"] | Should -Be "foo"
            $converted["section"]["bar"] | Should -Be "3.1415"
            $converted["section"]["baz"] | Should -Be "…"
        }

        It "processes arrays in nested objects" {
            $converted["section with array"]["array"] | Should -Be @("lorem", "ipsum", "dolor")
        }

        It "processes nested objects in nested objects" {
            $converted["prop"]["nestedProp"] | Should -Be "@{array=item; key=string}"
        }
    }
}
