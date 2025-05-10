function Import-Ini {
    <#
    .Synopsis
        Gets the content of an INI file

    .Description
        Gets the content of an INI file and returns it as a hashtable

    .Inputs
        System.String

    .Outputs
        System.Collections.Specialized.OrderedDictionary

    .Example
        $FileContent = Import-Ini "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

    .Example
        $inifilepath | $FileContent = Import-Ini
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

    .Example
        C:\PS>$FileContent = Import-Ini "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file

    .Link
        Export-Ini
        ConvertFrom-Ini
        ConvertTo-Ini
    #>

    [CmdletBinding()]
    [OutputType( [System.Collections.Specialized.OrderedDictionary] )]
    param(
        # Specifies the path to an item.
        # This cmdlet gets the item at the specified location.
        # Wildcard characters are permitted.
        # This parameter is required, but the parameter name Path is optional.
        #
        # Use a dot (`.`) to specify the current location. Use the wildcard character (`*`) to specify all the items in the current location.
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Path", Position = 0 )]
        [Alias("PSPath", "FullName")]
        [String[]]
        $Path,

        # Specifies a path to one or more locations.
        # The value of LiteralPath is used exactly as it's typed.
        # No characters are interpreted as wildcards.
        # If the path includes escape characters, enclose it in single quotation marks.
        # Single quotation marks tell PowerShell not to interpret any characters as escape sequences.
        #
        # For more information, see about_Quoting_Rules
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "LiteralPath" )]
        [String[]]
        $LiteralPath,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Parameter()]
        [Char[]]
        $CommentChar = @(";"),

        # Remove lines determined to be comments from the resulting dictionary.
        [Switch]
        $IgnoreComments,

        # Remove sections without any key
        [Switch]
        $IgnoreEmptySections
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $listOfCommentChars = $CommentChar -join ''
        $commentRegex = "^[$listOfCommentChars](.*)$"
        $sectionRegex = "^\s*\[(.+)\]"
        $keyRegex = "^([^$listOfCommentChars]+?)=(.*)$"

        Write-DebugMessage ("commentRegex is $commentRegex")
        Write-DebugMessage ("sectionRegex is $sectionRegex")
        Write-DebugMessage ("keyRegex is $keyRegex")
    }

    process {
        $ResolvedPath = if ($Path) { Resolve-Path $Path }
        else { $LiteralPath }

        foreach ($file in $ResolvedPath) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $file"

            if (-not (Test-Path -LiteralPath $file)) {
                Write-Error "Could not find file '$file'"
                continue
            }
            $file = [WildcardPattern]::Escape($file)

            $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $section = $null # Section Name
            $name = $null # Key or Comment Name

            $commentCount = 0
            switch -regex -file $file {
                $sectionRegex {
                    # Section
                    $section = $matches[1]
                    Write-Debug "$($MyInvocation.MyCommand.Name):: Adding section : $section"
                    $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    $commentCount = 0
                    continue
                }
                $commentRegex {
                    # Comment
                    if (-not $IgnoreComments) {
                        if (-not $section) {
                            $section = $script:NoSection
                            $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                        }
                        $value = $matches[1].Trim()
                        $commentCount++
                        Write-DebugMessage ("Incremented commentCount is now $commentCount.")
                        $name = "Comment$commentCount"
                        Write-Debug "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                        $ini[$section][$name] = $value
                    }
                    else {
                        Write-DebugMessage ("Ignoring comment $($matches[1]).")
                    }
                    continue
                }
                $keyRegex {
                    # Key
                    if (-not $section) {
                        $section = $script:NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $name, $value = $matches[1].Trim(), $matches[2].Trim()
                    if (-not [string]::IsNullOrWhiteSpace($name)) {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name with value: $value"
                        if (-not $ini[$section][$name]) {
                            $ini[$section][$name] = $value
                        }
                        else {
                            if ($ini[$section][$name] -is [string]) {
                                $oldValue = $ini[$section][$name]
                                $ini[$section][$name] = [System.Collections.ArrayList]::new()
                                $null = $ini[$section][$name].Add($oldValue)
                            }
                            $null = $ini[$section][$name].Add($value)
                        }
                    }
                    continue
                }
                Default {
                    # No match
                    # As seen in https://github.com/lipkau/PSIni/issues/65, some software writes keys without
                    # the `=` sign.
                    if (-not $section) {
                        $section = $script:NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $name = $_.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($name)) {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name without a value"
                        $ini[$section][$name] = $null
                    }
                    continue
                }
            }
            if ($IgnoreEmptySections) {
                $ToRemove = [System.Collections.ArrayList]@()
                foreach ($Section in $ini.Keys) {
                    if (($ini[$Section]).Count -eq 0) {
                        $null = $ToRemove.Add($Section)
                    }
                }
                foreach ($Section in $ToRemove) {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Removing empty section $Section"
                    $null = $ini.Remove($Section)
                }
            }
            $ini
        }
    }

    end {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias ipini Import-Ini
