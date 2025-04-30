#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "General project validation" -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
    }
    AfterEach {
        Remove-Module PSIni -ErrorAction SilentlyContinue
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module 'PSIni' can import cleanly" {
        Remove-Module "PSIni" -ErrorAction SilentlyContinue
        Get-Module "PSIni" | Should -BeNullOrEmpty

        Import-Module $moduleToTest
        Get-Module "PSIni" | Should -Not -BeNullOrEmpty
    }

    It "module 'PSIni' exports functions" {
        Import-Module $moduleToTest
        (Get-Command -Module "PSIni" | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module has the correct name" {
        $manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.Name | Should -Be "PSIni"
    }

    It "module uses the correct moduleroot" {
        $manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.RootModule | Should -Be "PSIni.psm1"
    }

    It "module uses the correct guid" {
        $manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.Guid | Should -Be '98e1dc0f-2f03-4ca1-98bb-fd7b4b6ac652'
    }

    It "module uses a valid version" {
        $manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.Version -as [Version] | Should -Not -BeNullOrEmpty
    }

    It "module manifest only define major and minor verions" {
        $manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.Version | Should -Match '^\d+\.\d+$'
    }
}
