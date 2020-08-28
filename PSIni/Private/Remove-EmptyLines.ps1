function Remove-EmptyLines {
    param(
        $Append,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Encoding = "UTF8",

        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,

        $Force
    )

    $lf = if ((-not $PSVersionTable.Platform) -or ($PSVersionTable.Platform -eq "Win32NT")) { "\r\n" }
    else { "\n" }

    $content = (Get-Content -Path $FilePath -Raw) -replace "(${lf})*$", "" -replace "(${lf}){3,}", ""
    Set-Content -Value $content -Path $FilePath -Encoding $Encoding -Force
}
