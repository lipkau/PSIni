#requires -Version 2.0

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
    [OutputType(
        [System.Collections.Specialized.OrderedDictionary]
    )]
    param(
        # Specifies the path to the input file.
        [ValidateNotNullOrEmpty()]
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        [String[]]
        $Path,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Char[]]
        $CommentChar = @(";"),

        # Remove lines determined to be comments from the resulting dictionary.
        [Switch]
        $IgnoreComments
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $commentRegex = "^\s*([$($CommentChar -join '')].*)$"
        $sectionRegex = "^\s*\[(.+)\]\s*$"
        $keyRegex = "^\s*(.+?)\s*=\s*(['`"]?)(.*)\2\s*$"

        Write-DebugMessage ("commentRegex is {0}." -f $commentRegex)
        Write-DebugMessage ("section is {0}." -f $sectionRegex)
        Write-DebugMessage ("key is {0}." -f $keyRegex)
    }

    process {
        foreach ($file in $Path) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $file"

            $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)

            if (!(Test-Path $file)) {
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
                    if (!$IgnoreComments) {
                        if (!(test-path "variable:local:section")) {
                            $section = $script:NoSection
                            $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                        }
                        $value = $matches[1]
                        $CommentCount++
                        Write-DebugMessage ("Incremented CommentCount is now {0}." -f $CommentCount)
                        $name = "Comment" + $CommentCount
                        Write-Debug "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                        $ini[$section][$name] = $value
                    }
                    else {
                        Write-DebugMessage ("Ignoring comment {0}." -f $matches[1])
                    }

                    continue
                }
                $keyRegex {
                    # Key
                    if (!(test-path "variable:local:section")) {
                        $section = $script:NoSection
                        $ini[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                    }
                    $name, $value = $matches[1, 3]
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding key $name with value: $value"
                    if (-not $ini[$section][$name]) {
                        $ini[$section][$name] = $value
                    }
                    else {
                        if ($ini[$section][$name] -is [string]) {
                            $oldValue = $ini[$section][$name]
                            $ini[$section][$name] = [System.Collections.ArrayList]::new()
                            $null = $ini[$section][$name].Add($oldValue)
                            $null = $ini[$section][$name].Add($value)
                        }
                        else {
                            $null = $ini[$section][$name].Add($value)
                        }
                    }
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

Set-Alias ipi Import-Ini
