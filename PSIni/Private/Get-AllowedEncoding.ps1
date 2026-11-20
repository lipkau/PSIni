function Get-AllowedEncoding {
    # Use the built-in cmdlet; another module can define its own Out-File
    $command = Get-Command -Name Out-File -Module Microsoft.PowerShell.Utility -CommandType Cmdlet

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        (
            $command.Parameters['Encoding'].Attributes |
                Where-Object { $_ -is [ArgumentCompletions] }
        )[0].CompleteArgument('Out-File', 'Encoding', '*', $null, @{ }).CompletionText
    }
    else {
        (
            $command.Parameters['Encoding'].Attributes |
                Where-Object { $_.TypeId -eq [ValidateSet] }
        )[0].ValidValues
    }
}
