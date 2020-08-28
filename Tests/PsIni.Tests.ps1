#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

Describe "General project validation" -Tag Unit {
    BeforeAll {
        $moduleRoot = (Join-Path $PSScriptRoot "../PSIni")
        $moduleManifest = (Join-Path $moduleRoot "PSIni.psd1")
    }
    BeforeEach {
        Remove-Module PsIni -ErrorAction SilentlyContinue
        Import-Module $moduleRoot -Force -ErrorAction Stop
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $moduleManifest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module 'PsIni' can import cleanly" {
        Remove-Module "PsIni"
        Get-Module "PsIni" | Should -BeNullOrEmpty

        Import-Module $moduleRoot
        Get-Module "PsIni" | Should -Not -BeNullOrEmpty
    }

    It "module 'PsIni' exports functions" {
        (Get-Command -Module "PsIni" | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module has the correct name" {
        $manifest = Test-ModuleManifest -Path $moduleManifest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.Name | Should -Be "PsIni"
    }

    It "module uses the correct moduleroot" {
        $manifest = Test-ModuleManifest -Path $moduleManifest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.RootModule | Should -Be "PsIni.psm1"
    }

    It "module uses the correct guid" {
        $manifest = Test-ModuleManifest -Path $moduleManifest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.Guid | Should -Be '98e1dc0f-2f03-4ca1-98bb-fd7b4b6ac652'
    }

    It "module uses a valid version" {
        $manifest = Test-ModuleManifest -Path $moduleManifest -ErrorAction Stop -WarningAction SilentlyContinue
        $manifest.Version -as [Version] | Should -Not -BeNullOrEmpty
    }
}
