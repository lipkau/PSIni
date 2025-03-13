filter isNumeric() {
    return $_ -is [byte] -or $_ -is [int16] -or $_ -is [int32] -or $_ -is [int64]  `
        -or $_ -is [sbyte] -or $_ -is [uint16] -or $_ -is [uint32] -or $_ -is [uint64] `
        -or $_ -is [float] -or $_ -is [double] -or $_ -is [decimal]
}
