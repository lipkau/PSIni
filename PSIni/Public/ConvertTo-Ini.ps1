#requires -Version 5

function ConvertTo-Ini {
    <#
    .Synopsis
        Transform a Powershell Object to a format that can be stored as an INI file.

    .Description
        Will transform any given object to a nested (one leve) OrderedDictionary that can be stored as an INI file.

        Any nesting that goes beyond 1 level will be stored using the `toString()` method.
        Caution: using this cmdlet via pipeline might result in unwanted behavior, as the key might be duplicated.

    .Example
        Get-ChildItem | ConvertTo-Ini
        -----------
        Description
        Will output a Dictionary object which can be stored as INI file.
        As each file in the directory has the same properties, the Dictionary will contain duplicate key names.

    .Example
        '{ "data": { "timestamp": "2020-01-01 12:00:00", "values": ["jon.doe", "jane.doe"] } }' | ConvertFrom-Json | ConvertTo-Ini
        -----------
        Description
        Will output a Dictionary object which can be stored as INI file.

    .Example
        @{ data = @{ nested = (Get-Date) } } | ConvertTo-Ini
        -----------
        Description
        Will output a Dictionary object which can be stored as INI file.
        However, the DateTime object is stored in it's `toString()` format:
        @{value=09/17/2020 13:12:43; DisplayHint=2; DateTime=Thursday, 17 September 2020 13:12:43}

    .Example
        @{ data = @{ nested = (Get-Date) } } | ConvertTo-Ini | Export-Ini .\output.ini
        -----------
        Description
        This examples shows how to use ConvertTo-Ini with Export-Ini to create an INI file on disk based on a
        powershell object.

    .Link
        ConvertFrom-ini
        Import-Ini
        Export-Ini
    #>
    [CmdletBinding( )]
    [OutputType( [System.Collections.Specialized.OrderedDictionary] )]
    param(
        # Object to convert
        [Parameter( Mandatory, ValueFromPipeline )]
        [Object]
        $InputObject
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        function New-Array {
            param($InputObject)
            $output = [System.Collections.ArrayList]::new()
            foreach ($item in $InputObject) { $null = $output.Add([String]($item)) }
            $output
        }
    }

    process {
        # use json to limit the depth and sanitize data types
        $data = ConvertTo-Json $InputObject | ConvertFrom-Json -Depth 3

        $output = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)

        foreach ($section in $data.PSObject.Properties.Name) {
            if ($data.$section -is [System.Collections.IList]) {
                Write-DebugMessage "$($MyInvocation.MyCommand.Name):: Creating new root level array for '$section'"
                $output.$section = New-Array $data.$section
            }
            elseif ($data.$section -is [PSCustomObject]) {
                Write-DebugMessage "$($MyInvocation.MyCommand.Name):: Creating new section for '$section'"
                $output.$section = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)

                foreach ($key in $data.$section.PSObject.Properties.Name) {
                    if ($data.$section.$key -is [System.Collections.IList]) {
                        Write-DebugMessage "$($MyInvocation.MyCommand.Name):: Creating new array '$key' in section '$section'"
                        $output.$section.$key = New-Array $data.$section.$key
                    }
                    else {
                        Write-DebugMessage "$($MyInvocation.MyCommand.Name):: Creating new key '$key' in section '$section'"
                        $output.$section.$key = [String]($data.$section.$key)
                    }
                }
            }
            else {
                Write-DebugMessage "$($MyInvocation.MyCommand.Name):: Adding new root level key '$section'"
                $output[$section] = [String]($data.$section)
            }
        }

        $output
    }

    end {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}
