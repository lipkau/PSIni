function Remove-EmptyLine {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Encoding = "UTF8",

        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        $Force
    )

    $lf = if ((-not $PSVersionTable.Platform) -or ($PSVersionTable.Platform -eq "Win32NT")) { "\r\n" }
    else { "\n" }

    # TODO: Verify if this code is actually necessary & purge from the codebase, if not.
    # Makes sure that there are no more than singular empty lines in entire file & that the file ends without empty lines
    $content = (Get-Content -Path $Path -Raw) -replace "(${lf})*$", "" -replace "(${lf}){3,}", ""
    Set-Content -Value $content -Path $Path -Encoding $Encoding -Force:$Force
}
