Set-StrictMode -Version Latest
Function Uncomment-IniContent {
    <#
    .Synopsis
        Uncomments out specified content of an INI file

    .Description
        Uncomments out specified keys in all sections or certain sections.
        The ini source can be specified by a file or piped in by the result of Get-IniContent.
        The modified content is returned as a ordered dictionary hashtable and can be piped to a file with Out-IniFile.

    .Notes
        Author		: Sean Seymour <seanjseymour@gmail.com> based on work by Oliver Lipkau <oliver@lipkau.net>
		Source		: https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version		: 1.0.0 - 2016/08/05 - SS - Initial release

        #Requires -Version 2.0

    .Inputs
        System.String
        System.Collections.IDictionary

    .Outputs
        System.Collections.Specialized.OrderedDictionary

    .Parameter FilePath
        Specifies the path to the input file.

    .Parameter InputObject
        Specifies the Hashtable to be modified. Enter a variable that contains the objects or type a command or expression that gets the objects.

    .Parameter CommentChar
        Specify what character should be removed to uncomment keys.
        Default: ";"

    .Parameter Keys
        String of one or more keys to modify, separated by a delimiter. Default is a comma, but this can be changed with -KeyDelimiter. Required.

    .Parameter KeyDelimiter
        Specify what character should be used to split the -Keys parameter value.
        Default: ","

    .Parameter Sections
        String of one or more sections to limit the changes to, separated by a delimiter. Default is a comma, but this can be changed with -SectionDelimiter.
        Surrounding section names with square brackets is not necessary but is supported.
        Ini keys that do not have a defined section can be modified by specifying '_' (underscore) for the section.

    .Parameter SectionDelimiter
        Specify what character should be used to split the -Sections parameter value.
        Default: ","

    .Example
        $ini = Uncomment-IniContent -FilePath "C:\myinifile.ini" -Sections 'Printers' -Keys 'Headers'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, uncomments out any keys named 'Headers' in the [Printers] section, and saves the modified ini to $ini.

    .Example
        Uncomment-IniContent -FilePath "C:\myinifile.ini" -Sections 'Terminals,Monitors' -Keys 'Updated' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and uncomments out any keys named 'Updated' in the [Terminals] and [Monitors] sections.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Uncomment-IniContent -Keys 'Headers' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Uncomment-IniContent to uncomment any 'Headers' keys in any
        section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Uncomment-IniContent -Keys 'Updated' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Uncomment-IniContent to uncomment any 'Updated' keys that
        are orphaned, i.e. not specifically in a section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini.

    .Link
        Get-IniContent
        Out-IniFile
    #>

    [CmdletBinding(DefaultParameterSetName = "File")]
    Param
    (
        [Parameter(ParameterSetName="File",Mandatory=$True,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$FilePath,

        [Parameter(ParameterSetName="Object",Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]$InputObject,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$Keys,

        [String]$KeyDelimiter = ',',

        [String]$CommentChar = ';',

        [ValidateNotNullOrEmpty()]
        [String]$Sections,
        [String]$SectionDelimiter = ','
    )

    Begin
    {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) { $DebugPreference = 'Continue' }
        Write-Debug "DebugPreference: $DebugPreference"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        Function Convert-IniCommentToEntry
        {
            param ($content, $key, $section)

            $index = 0
            $commentFound = $false

            $commentValue = $CommentChar + $key
            Write-Debug("commentValue is '{0}'." -f $commentValue)

            foreach ($entry in $content[$section].GetEnumerator())
            {
                Write-Debug("Uncomment looking for key '{0}' with value '{1}'." -f $entry.key, $entry.value)

                if ($entry.key.StartsWith('Comment') -and $entry.value -match $commentValue)
                {
                    Write-Verbose("$($MyInvocation.MyCommand.Name):: Uncommenting '{0}' in {1} section." -f $entry.value, $section)
                    $oldKey = $entry.key
                    $split = $entry.value.Split("=")

                    if ($split.Length -ge 2)
                    {
                        $newValue = $split[1].Trim()
                    }
                    else
                    {
                        # If the split did not result in 2+ items, it was not in the key=value form.
                        # So just uncomment the key, as there is no value. It will result in a "key=" formatted output.
                        $newValue = ''
                    }

                    # Break out once a match is found. If there are multiple commented out keys
                    # with the same name, we can't add them anyway since it's a hash.
                    $commentFound = $true
                    break
                }
                $index++
            }

            if ($commentFound)
            {
                if ($content[$section][$key])
                {
                    Write-Verbose("$($MyInvocation.MyCommand.Name):: Unable to uncomment '{0}' key in {1} section as there is already a key with that name." -f $key, $section)
                }
                else
                {
                    Write-Debug("Removing '{0}'." -f $oldKey)
                    $content[$section].Remove($oldKey)
                    Write-Debug("Inserting [{0}][{1}] = {2} at index {3}." -f $section, $key, $newValue, $index)
                    $content[$section].Insert($index, $key, $newValue)
                }
            }
            else
            {
                Write-Verbose("$($MyInvocation.MyCommand.Name):: Did not find '{0}' key in {1} section to uncomment." -f $key, $section)
            }
        }
    }
    # Uncomment out the specified keys in the list, either in the specified section or in all sections.
    Process
    {
        # Get the ini from either a file or object passed in.
        if ($PSCmdlet.ParameterSetName -eq 'File') { $content = Get-IniContent $FilePath }
        if ($PSCmdlet.ParameterSetName -eq 'Object') { $content = $InputObject }

        # Specific section(s) were requested.
        if ($Sections)
        {
            foreach ($section in $Sections.Split($SectionDelimiter))
            {
                # Get rid of whitespace and section brackets.
                $section = $section.Trim() -replace '[][]',''

                Write-Debug("Processing '{0}' section." -f $section)

                foreach ($key in $Keys.Split($KeyDelimiter))
                {
                    Write-Debug("Processing '{0}' key." -f $key)

                    $key = $key.Trim()

                    if (!($content[$section]))
                    {
                        Write-Verbose("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist." -f $section)
                        # Break out of the loop after this, because we don't want to check further keys for this non-existent section.
                        break
                    }
                    # Since this is a comment, we need to search through all the CommentX keys in this section.
                    # That's handled in the Convert-IniCommentToEntry function, so don't bother checking key existence here.
                    Convert-IniCommentToEntry $content $key $section
                }
            }
        }
        else # No section supplied, go through the entire ini since changes apply to all sections.
        {
            foreach ($item in $content.GetEnumerator())
            {
                $section = $item.key
                Write-Debug("Processing '{0}' section." -f $section)

                foreach ($key in $Keys.Split($KeyDelimiter))
                {
                    $key = $key.Trim()
                    Write-Debug("Processing '{0}' key." -f $key)
                    Convert-IniCommentToEntry $content $key $section
                }
            }
        }

        return $content
    }
    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias uncomment-ini Uncomment-IniContent
