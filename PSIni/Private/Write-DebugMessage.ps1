function Write-DebugMessage {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        $Message
    )

    begin {
        $oldDebugPreference = $DebugPreference
        if (!($DebugPreference -eq "SilentlyContinue")) {
            $DebugPreference = 'Continue'
        }
    }

    process {
        Write-Debug $Message
    }

    end {
        $DebugPreference = $oldDebugPreference
    }
}
