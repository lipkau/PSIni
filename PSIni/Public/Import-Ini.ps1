#requires -Version 5

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
        # Specifies the path to the input file.
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [Alias("PSPath", "FullName")]
        [String[]]
        $Path,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Parameter()]
        [Char[]]
        $CommentChar = @(";"),

        # Remove lines determined to be comments from the resulting dictionary.
        [Switch]
        $IgnoreComments
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $listOfCommentChars = $CommentChar -join ''
        $commentRegex = "^\s*[$listOfCommentChars](.*)$"
        $sectionRegex = "^\s*\[(.+)\]\s*$"
        $keyRegex = "^\s*([^$listOfCommentChars]+?)\s*=\s*(['`"]?)(.*)\2\s*$"

        Write-DebugMessage ("commentRegex is $commentRegex")
        Write-DebugMessage ("sectionRegex is $sectionRegex")
        Write-DebugMessage ("keyRegex is $keyRegex")
    }

    process {
        foreach ($file in $Path) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $file"

            $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
            $section = $null

            if (-not (Test-Path -Path $file)) {
                Write-Error "Could not find file '$file'"
            }

            $commentCount = 0
            switch -regex -file $file {
                $sectionRegex {
                    # Section
                    $section = $matches[1]
                    Write-Debug "$($MyInvocation.MyCommand.Name):: Adding section : $section"
                    $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    $CommentCount = 0
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
                        $CommentCount++
                        Write-DebugMessage ("Incremented CommentCount is now $CommentCount.")
                        $name = "Comment$CommentCount"
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
                    $name, $value = $matches[1].Trim(), $matches[3].Trim()
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
                    continue
                }
                Default {
                    # No match
                    # As seen in https://github.com/lipkau/PsIni/issues/65, some software writes keys without
                    # the `=` sign.
                    if (-not $section) {
                        $section = $script:NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $name = $_
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name without a value"
                    $ini[$section][$name] = $null
                    continue
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
