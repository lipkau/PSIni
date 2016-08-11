Set-StrictMode -Version Latest
Function Comment-IniContent {
    <#
    .Synopsis
        Comments out specified content of an INI file

    .Description
        Comments out specified keys in all sections or certain sections.
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
        Specify what character should be used to comment out keys.
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
        $ini = Comment-IniContent -FilePath "C:\myinifile.ini" -Sections 'Printers' -Keys 'Headers'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, comments out any keys named 'Headers' in the [Printers] section, and saves the modified ini to $ini.

    .Example
        Comment-IniContent -FilePath "C:\myinifile.ini" -Sections 'Terminals,Monitors' -Keys 'Updated' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and comments out any keys named 'Updated' in the [Terminals] and [Monitors] sections.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Comment-IniContent -Keys 'Headers' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Comment-IniContent to comment out any 'Headers' keys in any
        section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Comment-IniContent -Keys 'Updated' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Comment-IniContent to comment out any 'Updated' keys that
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

        # Remove the old key then insert a new one at the old location in the comment style used by Get-IniContent.
        Function Convert-IniEntryToComment
        {
            param ($content, $key, $section)

            # Comments in Get-IniContent start with 1, not zero.
            $commentCount = 1

            foreach ($entry in $content[$section].GetEnumerator())
            {
                if ($entry.key.StartsWith('Comment')) { $commentCount++ }
            }

            $desiredValue = $content[$section][$key]

            # Don't attempt to comment out non-existent keys.
            if ($desiredValue)
            {
                $commentKey = 'Comment' +  $commentCount
                $commentValue = $CommentChar + $key + '=' + $desiredValue

                # Thanks to http://stackoverflow.com/a/35731603/844937. However, that solution is case sensitive.
                # Tried $index = $($content[$section].keys).IndexOf($key, [StringComparison]"CurrentCultureIgnoreCase")
                # but it said there were no IndexOf overloads with two arguments. So if we get a -1 (not found),
                # use a variation on http://stackoverflow.com/a/34930231/844937 to search for a case-insensitive match.
                $sectionKeys = $($content[$section].keys)
                $index = $sectionKeys.IndexOf($key)
                Write-Debug("Index of {0} is {1}." -f $key, $index)

                if ($index -eq -1)
                {
                    $i = 0
                    foreach ($sectionKey in $sectionKeys)
                    {
                        if ($sectionKey -match $key)
                        {
                            $index = $i
                            Write-Debug("Index updated to {0}." -f $index)
                            break
                        }
                        else { $i++ }
                    }
                }

                if ($index -ge 0)
                {
                    Write-Verbose("$($MyInvocation.MyCommand.Name):: Commenting out {0} key in {1} section." -f $key, $section)
                    $content[$section].Remove($key)
                    $content[$section].Insert($index, $commentKey, $commentValue)
                }
                else
                {
                    Write-Verbose("$($MyInvocation.MyCommand.Name):: Could not find '{0}' key in {1} section to comment out." -f $key, $section)
                }
            }
        }
    }
    # Comment out the specified keys in the list, either in the specified section or in all sections.
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

                    if ($content[$section]) { $currentValue = $content[$section][$key] }
                    else
                    {
                        Write-Verbose("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist." -f $section)
                        # Break out of the loop after this, because we don't want to check further keys for this non-existent section.
                        break
                    }

                    if ($currentValue) { Convert-IniEntryToComment $content $key $section }
                    else { Write-Verbose("$($MyInvocation.MyCommand.Name):: '{0}' key does not exist." -f $key) }
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

                    if ($content[$section][$key]) { Convert-IniEntryToComment $content $key $section }
                    else { Write-Verbose("$($MyInvocation.MyCommand.Name):: '{0}' key does not exist." -f $key) }
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

Set-Alias comment-ini Comment-IniContent
