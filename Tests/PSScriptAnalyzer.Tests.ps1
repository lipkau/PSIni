#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
#requires -modules PSScriptAnalyzer

Describe "PSScriptAnalyzer Tests" -Tag "Unit" {
    BeforeDiscovery {
        $script:moduleToTestRoot = "$PSScriptRoot/.."
        ${/} = [System.IO.Path]::DirectorySeparatorChar

        $isaSplat = @{
            Path          = $moduleToTestRoot
            Settings      = "$moduleToTestRoot/PSScriptAnalyzerSettings.psd1"
            Severity      = @('Error', 'Warning')
            Recurse       = $true
            Verbose       = $false
            ErrorVariable = 'ErrorVariable'
            ErrorAction   = 'Stop'
        }
        $script:scriptWarnings = Invoke-ScriptAnalyzer @isaSplat | Where-Object { $_.ScriptPath -notlike "*${/}release${/}PSIni${/}PSIni.psd1" }
        # $script:foo = $scriptWarnings | Where-Object { $_.Severity -eq "Warning" }
        $script:moduleFiles = Get-ChildItem $moduleToTestRoot -Recurse
    }

    # Describe "Testing <_> Rules" { #-ForEach @("Information", "Warning", "Error") {
    #     # BeforeDiscovery {
    #     #     $script:foo = $scriptWarnings | Where-Object { $_.Severity -eq "Information" }
    #     # }

    #     It "Rule: <RuleName>" -TestCases $foo {
    #         $_ |
    #             # ForEach-Object { "Problem in $($_.ScriptName) at line $($_.Line) with message: $($_.Message)" } |
    #             Should -BeNullOrEmpty
    #     }
    # }

    It "has no script analyzer warnings" {
        $scriptWarnings | Should -HaveCount 0
    }

    Describe "File <_.Name>" -ForEach $moduleFiles {
        BeforeAll {
            $script:file = $_
        }
        It "has no script analyzer warnings" {
            $scriptWarnings |
                Where-Object { $_.ScriptPath -like $file.FullName } |
                ForEach-Object { "Problem in $($_.ScriptName) at line $($_.Line) with message: $($_.Message)" } |
                Should -BeNullOrEmpty
        }
    }

    # $Rules = $ScriptWarnings |
    # Where-Object { $_.ScriptPath -like $Script.FullName } |
    # Select-Object -ExpandProperty RuleName -Unique

    # foreach ($rule in $Rules) {
    #     It "passes $rule" {
    #         $BadLines = $ScriptWarnings |
    #         Where-Object { $_.ScriptPath -like $Script.FullName -and $_.RuleName -like $rule } |
    #         Select-Object -ExpandProperty Line
    #         $BadLines | Should -Be $null
    #     }
    # }

    It "has no parse errors" {
        $Exceptions = $null
        if ($ErrorVariable) {
            $Exceptions = $ErrorVariable.Exception.Message |
                Where-Object { $_ -match [regex]::Escape($Script.FullName) }
        }

        foreach ($Exception in $Exceptions) {
            $Exception | Should -BeNullOrEmpty
        }
    }
}
