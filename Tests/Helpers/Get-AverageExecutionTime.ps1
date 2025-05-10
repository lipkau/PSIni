function Get-AverageExecutionTime {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ScriptBlock]$ScriptBlock,

        [Int] $Count
    )

    process {
        $executionTimes = @()
        for ($i = 0; $i -lt $Count; $i++) {
            $executionTime = Measure-Command { & $ScriptBlock }
            $executionTimes += $executionTime.TotalMilliseconds
        }

        [Math]::Round(($executionTimes | Measure-Object -Average).Average, 2)
    }
}
