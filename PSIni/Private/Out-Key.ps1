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
        if (-not ($InputObject.GetEnumerator().Name)) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: No data found in '$InputObject'."
            return
        }

        foreach ($key in $InputObject.GetEnumerator().Name) {
            if ($key -like "$script:CommentPrefix*") {
                if ($IgnoreComments) {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Skipping comment: $key"
                }
                else {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                    $outputLines += "$CommentChar$($InputObject[$key])"
                }
            }
            # Only $null (or an empty collection) means "key without a value".
            # Falsy values such as 0, $false and '' are written as values.
            elseif ($null -eq $InputObject[$key] -or ($InputObject[$key] -is [System.Collections.ICollection] -and $InputObject[$key].Count -eq 0)) {
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
