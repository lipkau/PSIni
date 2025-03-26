function Get-AllowedEncoding {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        ((Get-Command Out-File).Parameters['Encoding'].Attributes | Where-Object { $_ -is [ArgumentCompletions] })[0].CompleteArgument('Out-File', 'Encoding', '*', $null, @{ }).CompletionText
    }
    else {
        ((Get-Command Out-File).Parameters['Encoding'].Attributes | Where-Object { $_.TypeId -eq [ValidateSet] })[0].ValidValues
    }
}
