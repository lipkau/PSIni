Function Get-IniContent {
    <#
    .Synopsis
        Gets the content of an INI file

    .Description
        Gets the content of an INI file and returns it as a hashtable

    .Notes
        Author		: Oliver Lipkau <oliver@lipkau.net>
		Source		: https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version		: 1.0.0 - 2010/03/12 - OL - Initial release
                      1.0.1 - 2014/12/11 - OL - Typo (Thx SLDR)
                                              Typo (Thx Dave Stiff)
                      1.0.2 - 2015/06/06 - OL - Improvment to switch (Thx Tallandtree)
                      1.0.3 - 2015/06/18 - OL - Migrate to semantic versioning (GitHub issue#4)
                      1.0.4 - 2015/06/18 - OL - Remove check for .ini extension (GitHub Issue#6)
                      1.1.0 - 2015/07/14 - CB - Improve round-tripping and be a bit more liberal (GitHub Pull #7)
                                           OL - Small Improvments and cleanup
                      1.1.1 - 2015/07/14 - CB - changed .outputs section to be OrderedDictionary
                      1.1.2 - 2016/08/18 - SS - Add some more verbose outputs as the ini is parsed,
                      				            allow non-existent paths for new ini handling,
                      				            test for variable existence using local scope,
                      				            added additional debug output.

        #Requires -Version 2.0

    .Inputs
        System.String

    .Outputs
        System.Collections.Specialized.OrderedDictionary

    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file

    .Link
        Out-IniFile
    #>

    [CmdletBinding()]
    [OutputType(
        [System.Collections.Specialized.OrderedDictionary]
    )]
    Param(
        # Specifies the path to the input file.
        [ValidateNotNullOrEmpty()]
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        [String]
        $FilePath,

        # Specify what characters should be describe a comment.
        # Lines starting with the characters provided will be rendered as comments.
        # Default: ";"
        [Char[]]
        $CommentChar = @(";"),

        # Remove lines determined to be comments from the resulting dictionary.
        [Switch]
        $IgnoreComments
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $commentRegex = "^\s*([$($CommentChar -join '')].*)$"
        $sectionRegex = "^\s*\[(.+)\]\s*$"
        $keyRegex     = "^\s*(.+?)\s*=\s*(['`"]?)(.*)\2\s*$"

        Write-Debug ("commentRegex is {0}." -f $commentRegex)
    }

    Process {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

        $ini = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
        #$ini = @{}

        if (!(Test-Path $Filepath)) {
            Write-Verbose ("Warning: `"{0}`" was not found." -f $Filepath)
            Write-Output $ini
        }

        $commentCount = 0
        switch -regex -file $FilePath {
            $sectionRegex {
                # Section
                $section = $matches[1]
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding section : $section"
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
                    Write-Debug ("Incremented CommentCount is now {0}." -f $CommentCount)
                    $name = "Comment" + $CommentCount
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding $name with value: $value"
                    $ini[$section][$name] = $value
                }
                else {
                    Write-Debug ("Ignoring comment {0}." -f $matches[1])
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
                        $ini[$section][$name] = [System.Collections.ArrayList]::new()
                        $ini[$section][$name].Add($ini[$section][$name]) | Out-Null
                        $ini[$section][$name].Add($value) | Out-Null
                    }
                    else {
                        $ini[$section][$name].Add($value) | Out-Null
                    }
                }
                continue
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
        Write-Output $ini
    }

    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias gic Get-IniContent
