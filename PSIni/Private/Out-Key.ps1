function Out-Key {
    param(
        [Parameter( Mandatory )]
        [Char]
        $CommentChar,

        [Parameter( Mandatory )]
        [String]
        $Delimiter,

        [Parameter( ValueFromPipeline )]
        [System.Collections.IDictionary]
        $InputObject,

        [Parameter()]
        [Switch]
        $IgnoreComments,

        [Parameter()]
        [Switch]
        $SkipTrailingEqualSign
    )

    begin {
        $outputLines = @()
    }

    process {
        if (-not ($InputObject.Keys)) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: No data found in '$InputObject'."
            return
        }

        foreach ($key in $InputObject.Keys) {
            if ($key -like "$script:CommentPrefix*") {
                if ($IgnoreComments) {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Skipping comment: $key"
                }
                else {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                    $outputLines += "$CommentChar$($InputObject[$key])"
                }
            }
            elseif (-not $InputObject[$key]) {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key without value"
                $outputLines += if ($SkipTrailingEqualSign) { "$key" } else { "${key}${Delimiter}" }
            }
            else {
                foreach ($entry in $InputObject[$key]) {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key"
                    $outputLines += "${key}${Delimiter}${entry}"
                }
            }
        }
    }

    end {
        return $outputLines
    }
}
