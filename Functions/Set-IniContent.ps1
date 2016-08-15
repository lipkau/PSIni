Set-StrictMode -Version Latest
Function Set-IniContent {
    <#
    .Synopsis
        Updates existing values or adds new key-value pairs to an INI file

    .Description
        Updates specified keys to new values in all sections or certain sections.
        Used to add new or change existing values. To comment, uncomment or remove keys use the related functions instead.
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

    .Parameter NameValuePairs
        String of one or more key names and values to modify, with the name/value separated by a delimiter and the pairs separated by another delimiter . Required.

    .Parameter NameValueDelimiter
        Specify what character should be used to split the names and values specified in -NameValuePairs.
        Default: "="

    .Parameter NameValuePairDelimiter
        Specify what character should be used to split the specified name-value pairs.
        Default: ","

    .Parameter Sections
        String of one or more sections to limit the changes to, separated by a delimiter. Default is a comma, but this can be changed with -SectionDelimiter.
        Surrounding section names with square brackets is not necessary but is supported.
        Ini keys that do not have a defined section can be modified by specifying '_' (underscore) for the section.

    .Parameter SectionDelimiter
        Specify what character should be used to split the -Sections parameter value.
        Default: ","

    .Example
        $ini = Set-IniContent -FilePath "C:\myinifile.ini" -Sections 'Printers' -NameValuePairs 'Name With Space=Value1,AnotherName=Value2'
        -----------
        Description
        Reads in the INI File c:\myinifile.ini, adds or updates the 'Name With Space' and 'AnotherName' keys in the [Printers] section to the values specified,
        and saves the modified ini to $ini.

    .Example
        Set-IniContent -FilePath "C:\myinifile.ini" -Sections 'Terminals,Monitors' -NameValuePairs 'Updated=FY17Q2' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini and adds or updates the 'Updated' key in the [Terminals] and [Monitors] sections to the value specified.
        The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Set-IniContent -NameValuePairs 'Headers=True,Update=False' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Set-IniContent to add or update the 'Headers'  and 'Update' keys in all sections
        to the specified values. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini. If the file is already present it will be overwritten.

    .Example
        Get-IniContent "C:\myinifile.ini" | Set-IniContent -NameValuePairs 'Updated=FY17Q2' -Sections '_' | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Reads in the INI File c:\myinifile.ini using Get-IniContent, which is then piped to Set-IniContent to add or update the 'Updated' key that
        is orphaned, i.e. not specifically in a section. The ini is then piped to Out-IniFile to write the INI File to c:\myinifile.ini.

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

        [Parameter(ParameterSetName="File",Mandatory=$True)]
        [Parameter(ParameterSetName="Object",Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$NameValuePairs,

        [String]$NameValueDelimiter = '=',
        [String]$NameValuePairDelimiter = ',',
        [String]$SectionDelimiter = ',',

        [Parameter(ParameterSetName="File")]
        [Parameter(ParameterSetName="Object")]
        [ValidateNotNullOrEmpty()]
        [String]$Sections
    )

    Begin
    {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) { $DebugPreference = 'Continue' }
        Write-Debug "DebugPreference: $DebugPreference"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        # Update or add the name/value pairs to the section.
        Function Update-IniEntry
        {
            param ($content, $section)

            foreach ($pair in $NameValuePairs.Split($NameValuePairDelimiter))
            {
                Write-Debug("Processing '{0}' pair." -f $pair)

                $splitPair = $pair.Split($NameValueDelimiter)

                if ($splitPair.Length -ne 2)
                {
                    Write-Warning("$($MyInvocation.MyCommand.Name):: Unable to split '{0}' into a distinct key/value pair." -f $pair)
                    continue
                }

                $key = $splitPair[0].Trim()
                $value = $splitPair[1].Trim()
                Write-Debug("Split key is {0}, split value is {1}" -f $key, $value)

                if (!($content[$section]))
                {
                    Write-Verbose("$($MyInvocation.MyCommand.Name):: '{0}' section does not exist, creating it." -f $section)
                    $content[$section] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
                }

                Write-Verbose("$($MyInvocation.MyCommand.Name):: Setting '{0}' key in section {1} to '{2}'." -f $key, $section, $value)
                $content[$section][$key] = $value
            }
        }
    }
    # Update the specified keys in the list, either in the specified section or in all sections.
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

                Update-IniEntry $content $section
            }
        }
        else # No section supplied, go through the entire ini since changes apply to all sections.
        {
            foreach ($item in $content.GetEnumerator())
            {
                $section = $item.key

                Write-Debug("Processing '{0}' section." -f $section)

                Update-IniEntry $content $section
            }
        }
        return $content
    }
    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias sic Set-IniContent
