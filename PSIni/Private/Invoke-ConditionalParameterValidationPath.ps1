function Invoke-ConditionalParameterValidationPath {
    param(
        $InputObject
    )

    if (-not (Test-Path $InputObject -IsValid)) {
        $errorItem = [System.Management.Automation.ErrorRecord]::new(
            ([System.ArgumentException]"Path not found"),
            'ParameterValue.FileNotFound',
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $InputObject
        )
        $errorItem.ErrorDetails = "Invalid path '$InputObject'."
        $PSCmdlet.ThrowTerminatingError($errorItem)
    }
    else {
        return $true
    }
}
