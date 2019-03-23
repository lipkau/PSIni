Function Remove-IniEntry {
    <#
    .Synopsis
        Removes specified content from an INI file

    .Description
        Removes specified keys in all sections or certain sections.
        The ini source can be specified by a file or piped in by the result of Get-IniContent.
        The modified content is returned as a ordered dictionary hashtable and can be piped to a file with Out-IniFile.

    .Notes
        Author		: Sean Seymour <seanjseymour@gmail.com> based on work by Oliver Lipkau <oliver@lipkau.net>
		Source		: https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version		: 1.0.0 - 2016/08/18 - SS - Initial release
                    : 1.0.1 - 2016/12/29 - SS - Removed need for delimiters by making Sections and Keys string arrays.

        #Requires -Version 2.0

    .Inputs
        System.String
        System.Collections.IDictionary

    .Outputs
        System.Collections.Specialized.OrderedDictionary

    .Example
        $ini = Remove-IniEntry -FilePath "C:\myinifile.ini" -Sections 'Printers' -Keys 'Headers','Version'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, removes any keys named 'Headers' or 'Version' in the [Printers] section, and saves the modified ini to $ini.

    .Example
        Remove-IniEntry -FilePath "C:\myinifile.ini" -Sections 'Terminals','Monitors' -Keys 'Updated' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and removes any keys named 'Updated' in the [Terminals] and [Monitors] sections.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniEntry -Keys 'Headers' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniEntry to remove any 'Headers' keys in any
        section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniEntry -Sections 'Terminals' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniEntry to remove the 'Terminals' section.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Remove-IniEntry -Keys 'Updated' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Remove-IniEntry to remove any 'Updated' keys that
        are orphaned, i.e. not specifically in a section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini.

    .Link
        Get-IniContent
        Out-IniFile
    #>

    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType(
        [System.Collections.IDictionary]
    )]
    Param
    (
        # Specifies the path to the input file.
        [Parameter( Position = 0, Mandatory = $true, ParameterSetName = "File")]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,

        # Specifies the Hashtable to be modified.
        # Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Object" )]
        [System.Collections.IDictionary]
        $InputObject,

        # String array of one or more keys to limit the changes to, separated by a comma. Optional.
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Keys,

        [ValidateNotNullOrEmpty()]
        [String[]]
        $Sections
    )

    Begin {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
    }
    # Remove the specified keys in the list, either in the specified section or in all sections.
    Process {
        # Get the ini from either a file or object passed in.
        if ($PSCmdlet.ParameterSetName -eq 'File') { $content = Get-IniContent $FilePath }
        if ($PSCmdlet.ParameterSetName -eq 'Object') { $content = $InputObject }

        if (!$Keys -and !$Sections) {
            Write-Verbose ("No sections or keys provided, exiting.")
            Write-Output $content
        }

        # Specific section(s) were requested.
        if ($Sections) {
            foreach ($section in $Sections) {
                # Get rid of whitespace and section brackets.
                $section = $section.Trim() -replace '[][]', ''

                Write-Debug ("Processing '{0}' section." -f $section)

                # If the user wants to remove an entire section, there will be a section specified but no keys.
                if (!$Keys) {
                    Write-Verbose ("Deleting entire section '{0}'." -f $section)
                    $content.Remove($section)
                }
                else {
                    foreach ($key in $Keys) {
                        Write-Debug ("Processing '{0}' key." -f $key)

                        $key = $key.Trim()

                        if ($content[$section]) {
                            $currentValue = $content[$section][$key]
                        }
                        else {
                            Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist." -f $section)
                            # Break out of the loop after this, because we don't want to check further keys for this non-existent section.
                            break
                        }

                        if ($currentValue) {
                            Write-Verbose ("Removing {0} key from {1} section." -f $key, $section)
                            $content[$section].Remove($key)
                        }
                        else {
                            Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' key does not exist." -f $key)
                        }
                    }
                }
            }
        }
        else {
            # No section supplied, go through the entire ini since changes apply to all sections.
            foreach ($item in $content.GetEnumerator()) {
                $section = $item.key
                Write-Debug ("Processing '{0}' section." -f $section)

                foreach ($key in $Keys) {
                    $key = $key.Trim()
                    Write-Debug ("Processing '{0}' key." -f $key)

                    if ($content[$section][$key]) {
                        Write-Verbose ("Removing {0} key from {1} section." -f $key, $section)
                        $content[$section].Remove($key)
                    }
                    else {
                        Write-Verbose ("$($MyInvocation.MyCommand.Name):: '{0}' key does not exist in {1} section." -f $key, $section)
                    }
                }
            }
        }

        Write-Output $content
    }
    End {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias rie Remove-IniEntry
