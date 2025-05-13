function Get-AllowedEncoding {
    $command = Get-Command -Name Out-File

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
