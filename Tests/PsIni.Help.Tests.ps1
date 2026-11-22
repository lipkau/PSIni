#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

Describe "Help tests" -Tag "Documentation", "Build" {
    BeforeDiscovery {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $DefaultParams = @(
            'Verbose'
            'Debug'
            'ErrorAction'
            'WarningAction'
            'InformationAction'
            'ProgressAction'
            'ErrorVariable'
            'WarningVariable'
            'InformationVariable'
            'OutVariable'
            'OutBuffer'
            'PipelineVariable'
            'WhatIf'
            'Confirm'
        )

        $script:commands = Get-Command -Module PSIni -CommandType Cmdlet, Function | ForEach-Object { @{
                Command     = $_
                CommandName = $_.Name
                Help        = (Get-Help $_.Name)
                Parameters  = @(
                    $_.Parameters.Keys | Where-Object { $_ -notin $DefaultParams } | ForEach-Object { @{ ParameterName = $_ } }
                )
            }
        }
    }

    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        Remove-Module PSIni -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop
    }

    Describe "Help content" {
        It "has a synopsis for <CommandName>" -TestCases $commands {
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "has a syntax for <CommandName>" -TestCases $commands {
            $help.syntax | Should -Not -BeNullOrEmpty
        }

        It "has a description for <CommandName>" -TestCases $commands {
            $help.Description.Text -join '' | Should -Not -BeNullOrEmpty
        }

        It "has examples for <CommandName>" -TestCases $commands {
            ($help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
        }

        It "has descriptions for all examples for <CommandName>" -TestCases $commands {
            foreach ($example in ($help.Examples.Example)) {
                $example.remarks.Text | Should -Not -BeNullOrEmpty
            }
        }

        It "has at least as many examples as ParameterSets for <CommandName>" -TestCases $commands {
            ($help.Examples.Example | Measure-Object).Count | Should -BeGreaterOrEqual $command.ParameterSets.Count
        }
    }

    Describe "Parameter help for <CommandName>" -ForEach $commands {
        It "has a description for parameter <ParameterName>" -TestCases $Parameters {
            $parameterHelp = $help.Parameters.Parameter | Where-Object { $_.Name -eq $ParameterName }
            $parameterHelp.Description.Text -join '' | Should -Not -BeNullOrEmpty
        }

        It "does not have parameters that are not in the code" {
            $helpParameters = @()
            if ($help.Parameters | Get-Member -Name Parameter) {
                $helpParameters = $help.Parameters.Parameter.Name | Sort-Object -Unique
            }
            foreach ($helpParameter in $helpParameters) {
                $command.Parameters.Keys | Should -Contain $helpParameter
            }
        }
    }
}
