function Invoke-ConditionalParameterValidationEncoding {
    param( [String] $InputObject )

    $allowedEncodings = Get-AllowedEncoding

    if ($InputObject -notin $allowedEncodings) {
        $errorItem = [System.Management.Automation.ErrorRecord]::new(
            ([System.ArgumentException]"Invalid Encoding"),
            'InvalidEncoding',
            [System.Management.Automation.ErrorCategory]::InvalidType,
            $InputObject
        )
        $errorItem.ErrorDetails = "Cannot validate argument on parameter 'Encoding'. The argument `"$InputObject`" does not belong to the set `"$($allowedEncodings -join ", ")`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."
        $PSCmdlet.ThrowTerminatingError($errorItem)
    }

    return $true
}
