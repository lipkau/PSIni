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
        [ValidateNotNullOrEmpty()]
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
        [ValidateNotNullOrEmpty()]
        [String[]]
        $LiteralPath,

        # The string representation of the INI file.
        [Parameter( Mandatory, ParameterSetName = "String" )]
        [ValidateNotNullOrEmpty()]
        [String]
        $InputString,

        # Specifies the file encoding.
        # The default is UTF8.
        [Parameter( ParameterSetName = "Path" )]
        [Parameter( ParameterSetName = "LiteralPath" )]
        [ValidateNotNullOrEmpty()]
        [System.Text.Encoding]
        $Encoding = [System.Text.Encoding]::UTF8,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Parameter()]
        [ValidateNotNullOrEmpty()]
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
        if ($Path) { $Sources = (Resolve-Path $Path) }
        elseif ($LiteralPath) { $Sources = $LiteralPath }
        elseif ($InputString) { $Sources = $InputString }

        foreach ($source in $Sources) {
            if ($LiteralPath -or $Path) {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $source"

                $source = (Get-Item -LiteralPath $source).FullName
                try { $fileContent = [System.IO.File]::ReadAllLines($source, $Encoding) }
                catch {
                    Write-Error "Could not find file '$source'"
                    continue
                }
            }
            else {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing a string"
                $fileContent = $source.split("`n")
            }

            $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $section, $name = $null
            $commentCount = 0

            foreach ($line in $fileContent) {
                switch -Regex ($line) {
                    $sectionRegex {
                        $section = $matches[1]
                        Write-Debug "$($MyInvocation.MyCommand.Name):: Adding section : $section"
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                        $commentCount = 0
                        continue
                    }
                    $commentRegex {
                        if (-not $IgnoreComments) {
                            if (-not $section) {
                                $section = $script:NoSection
                                $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                            }
                            $value = $matches[1].Trim()
                            $commentCount++
                            Write-DebugMessage ("Incremented commentCount is now $commentCount.")
                            $name = "$script:CommentPrefix$commentCount"
                            Write-Debug "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                            $ini[$section][$name] = $value
                        }
                        else {
                            Write-DebugMessage ("Ignoring comment $($matches[1]).")
                        }
                        continue
                    }
                    $keyRegex {
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
                        # As seen in https://github.com/lipkau/PSIni/issues/65, some software write keys without the `=` sign.
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
            }

            if ($IgnoreEmptySections) {
                $ToRemove = [System.Collections.ArrayList]@()
                foreach ($Section in $ini.GetEnumerator().Name) {
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
