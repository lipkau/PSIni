function Save-WithCleanup {
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

        $Force,

        [Parameter( Mandatory )]
        [Object[]]
        $FileContent
    )

    Set-Content -Value $FileContent -Path $Path -Encoding $Encoding -Force:$Force -NoNewline
}
