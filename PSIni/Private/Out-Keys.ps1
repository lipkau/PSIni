function Out-Keys {
    param(
        [Parameter()]
        [Switch]
        $Append,

        [Parameter( Mandatory )]
        [Char]
        $CommentChar,

        [Parameter( Mandatory )]
        [String]
        $Delimiter,

        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]
        $InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Encoding = "UTF8",

        [Parameter( Mandatory, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ -IsValid })]
        [Alias("PSPath", "FullName")]
        [String]
        $FilePath,

        [Parameter()]
        [Switch]
        $Force,

        [Parameter()]
        [Switch]
        $IgnoreComments,

        [Parameter()]
        [Switch]
        $SkipTrailingEqualSign
    )

    begin {
        $outFileParameter = @{
            Append   = $Append
            Encoding = $Encoding
            FilePath = $FilePath
            Force    = $Force
        }
    }

    process {
        if (-not ($InputObject.Keys)) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: No data found in '$InputObject'."
        }

        foreach ($key in $InputObject.Keys) {
            if ($key -like "Comment*") {
                if ($IgnoreComments) {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Skipping comment: $key"
                }
                else {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                    Out-File -InputObject "$CommentChar$($InputObject[$key])" @outFileParameter
                }
            }
            elseif (-not $InputObject[$key]) {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key without value"
                $keyToWrite = if ($SkipTrailingEqualSign) { "$key" } else { "$key$delimiter" }
                Out-File -InputObject $keyToWrite @outFileParameter
            }
            else {
                foreach ($entry in $InputObject[$key]) {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key"
                    Out-File -InputObject "$key$delimiter$entry" @outFileParameter
                }
            }
        }
    }
}
