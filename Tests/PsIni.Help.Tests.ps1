#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.0" }

New-Module PesterEx -ScriptBlock {
    function BeforeDiscovery ([ScriptBlock] $ScriptBlock) {
        . $ScriptBlock
    }
} -PassThru | Import-Module

Describe "Help tests" -Tag "Documentation", "Build" {
    BeforeAll {
        Remove-Module PsIni -ErrorAction SilentlyContinue
        Import-Module (Join-Path $PSScriptRoot "../PSIni") -Force -ErrorAction Stop

        $module = Get-Module PsIni

        $DefaultParams = @(
            'Verbose'
            'Debug'
            'ErrorAction'
            'WarningAction'
            'InformationAction'
            'ErrorVariable'
            'WarningVariable'
            'InformationVariable'
            'OutVariable'
            'OutBuffer'
            'PipelineVariable'
            'WhatIf'
            'Confirm'
        )
    }
    BeforeDiscovery {
        $commands = Get-Command -Module PsIni -CommandType Cmdlet, Function | Foreach-Object { @{
                Command     = $_
                CommandName = $_.Name
                Help        = (Get-Help $_.Name)
            }
        }
    }

    Describe "Help content" {
        It "has a synopsis for <CommandName>" -TestCases $commands {
            param($command, $CommandName, $Help)
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "has a syntax for <CommandName>" -TestCases $commands {
            param($command, $CommandName, $Help)
            $help.syntax | Should -Not -BeNullOrEmpty
        }

        It "has a description for <CommandName>" -TestCases $commands {
            param($command, $CommandName, $Help)
            $help.Description.Text -join '' | Should -Not -BeNullOrEmpty
        }

        It "has examples for <CommandName>" -TestCases $commands {
            param($command, $CommandName, $Help)
            ($help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
        }

        It "has desciptions for all examples for <CommandName>" -TestCases $commands {
            param($command, $CommandName, $Help)
            foreach ($example in ($help.Examples.Example)) {
                $example.remarks.Text | Should -Not -BeNullOrEmpty
            }
        }

        It "has at least as many examples as ParameterSets for <CommandName>" -TestCases $commands {
            param($command, $CommandName, $Help)
            ($help.Examples.Example | Measure-Object).Count | Should -BeGreaterOrEqual $command.ParameterSets.Count
        }

        <# foreach ($parameterName in $command.Parameters.Keys) {
                if ($help.Parameters | Get-Member -Name Parameter) {
                    $parameterHelp = $help.Parameters.Parameter | Where-Object { $_.Name -eq $parameterName }

                    if ($parameterName -notin $DefaultParams) {
                        It "has a description for parameter [<parameterName>] in <commandName>" -TestCases @{
                            parameterName = $parameterName
                            commandName   = $commandName
                            parameterHelp = $parameterHelp
                        } {
                            param($parameterName, $commandName, $parameterHelp)
                            $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                        }
                    }
                }
            }

            It "does not have parameters that are not in the code" -TestCases @{ help = $help; command = $command } {
                param($help, $command)
                $parameter = @()
                if ($help.Parameters | Get-Member -Name Parameter) {
                    $parameter = $help.Parameters.Parameter.Name | Sort-Object -Unique
                }
                foreach ($helpParm in $parameter) {
                    $command.Parameters.Keys | Should -Contain $helpParm
                }
            } #>
    }
    #endregion Public Functions
}
