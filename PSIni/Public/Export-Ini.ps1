function Export-Ini {
    <#
    .Synopsis
        Write hash content to INI file

    .Description
        Writes the content of a dictionary (such as a hashtable or the result of Import-Ini) to an INI file.

        Every key of the dictionary whose value is another dictionary becomes a section, and that dictionary holds the keys of the section.
        Every key whose value is not a dictionary is written as a key without a section.
        Keys stored under the section "_" (as Import-Ini does for keys outside of any section) are also written without a section header.
        Keys without a section are written before the first section of the InputObject (see -Append for an exception).
        Comments that Import-Ini read from a file are written back as comments, unless -IgnoreComments is used.

    .Inputs
        System.String
        System.Collections.IDictionary

    .Example
        Export-Ini "C:\myinifile.ini" -InputObject $IniVar
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini

    .Example
        $IniVar | Export-Ini "C:\myinifile.ini" -Force
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present

    .Example
        Export-Ini -InputObject $IniVar -LiteralPath "C:\[config]\myinifile.ini"
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File C:\[config]\myinifile.ini. LiteralPath does not treat the square brackets as wildcards.

    .Example
        $Category1 = @{"Key1"="Value1";"Key2"="Value2"}
        $Category2 = @{"Key1"="Value1";"Key2"="Value2"}
        $NewINIContent = @{"Category1"=$Category1;"Category2"=$Category2}
        Export-Ini -InputObject $NewINIContent -FilePath "C:\MyNewFile.ini"
        -----------
        Description
        Creating a custom Hashtable and saving it to C:\MyNewFile.ini

    .Example
        $NewINIContent = [ordered]@{ Name = "Value"; Section = @{ Key = "Value" } }
        Export-Ini -InputObject $NewINIContent -FilePath "C:\MyNewFile.ini"
        -----------
        Description
        Writes the key "Name" without a section at the top of the file, followed by the section "[Section]"

    .Example
        $Winpeshl = @{
            LaunchApp = @{
                AppPath = "%SYSTEMDRIVE%\Fabrikam\shell.exe"
            }
            LaunchApps = @{
                "%SYSTEMDRIVE%\Fabrikam\app1.exe" = $null
                '%SYSTEMDRIVE%\Fabrikam\app2.exe, /s "C:\Program Files\App3"' = $null
            }
        }
        Export-Ini -InputObject $Winpeshl -FilePath "winpeshl.ini" -SkipTrailingEqualSign
        -----------
        Description
        Example as per https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpeshlini-reference-launching-an-app-when-winpe-starts

    .Link
        Import-Ini
    #>

    [CmdletBinding( SupportsShouldProcess )]
    [OutputType( [Void] )]
    param(
        # Specifies the Hashtable to be written to the file.
        # Values that are dictionaries are written as sections, all other values as keys without a section.
        # Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory, ValueFromPipeline )]
        [System.Collections.IDictionary]
        $InputObject,

        # Specifies the path to the output file.
        [Parameter( Mandatory, Position = 0, ParameterSetName = "Path") ]
        [ValidateScript( { Invoke-ConditionalParameterValidationPath -InputObject $_ } )]
        [Alias( "Path" )]
        [String]
        $FilePath,

        # Specifies the path to the output file.
        # The LiteralPath parameter is used exactly as it's typed.
        # Wildcard characters aren't accepted.
        # If the path includes escape characters, enclose it in single quotation marks.
        # Single quotation marks tell PowerShell not to interpret any characters as escape sequences.
        # For more information, see about_Quoting_Rules.
        [Parameter( Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "LiteralPath" )]
        [Alias( "PSPath", "LP" )]
        [String]
        $LiteralPath,

        # Adds the output to the end of an existing file, instead of replacing the file contents.
        # Keys without a section are written at the end of the file too, so when the file already
        # contains sections, Import-Ini reads them as part of the last section. A warning is written in that case.
        # Without -Append, the first object from the pipeline replaces the file and the next ones are appended to it.
        [Switch]
        $Append,

        # Specifies the file encoding.
        # The default is UTF8.
        # The supported values are system dependent and can be listed with:
        # `(Get-Help -Name Out-File).parameters.parameter | ? name -eq Encoding`
        [Parameter()]
        [ValidateScript( { Invoke-ConditionalParameterValidationEncoding -InputObject $_ } )]
        [String]
        $Encoding = "UTF8",

        # Allows the cmdlet to overwrite an existing read-only file.
        # Even using the Force parameter, the cmdlet cannot override security restrictions.
        [Parameter()]
        [Switch]
        $Force,

        # NoClobber prevents an existing file from being overwritten and displays a message
        # that the file already exists.
        # By default, if a file exists in the specified path, it will be overwritten without warning.
        [Parameter()]
        [Alias( "NoOverwrite" )]
        [Switch]
        $NoClobber,

        # Specifies the character used to indicate a comment.
        [Parameter()]
        [String]
        $CommentChar = ";",

        # Determines the format of how to write the file.
        #
        # The following values are supported:
        #  - pretty: will write the file with an empty line between sections and whitespaces around the `=` sign
        #  - minified: will write the file in as few characters as possible
        [Parameter()]
        [ValidateSet("pretty", "minified")]
        [String]
        $Format = "pretty",

        # Will not write comments to the output file
        [Parameter()]
        [Switch]
        $IgnoreComments,

        # Does not add trailing = sign to keys without value.
        # A key has no value when its value is $null. An empty string is a value,
        # so it is still written with the = sign.
        # This behavior is needed for specific OS files, such as:
        # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpeshlini-reference-launching-an-app-when-winpe-starts
        [Parameter()]
        [Switch]
        $SkipTrailingEqualSign
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $delimiter = if ($Format -eq "pretty") { ' = ' } else { '=' }

        $targetPath = if ($LiteralPath) { $LiteralPath } else { $FilePath }

        # Same pattern Import-Ini uses to find a section header
        $sectionRegex = "^\s*\[(.+)\]"

        # Files written by this call, so the next object in the pipeline is appended to them
        $writtenPaths = New-Object -TypeName "System.Collections.Generic.HashSet[String]"

        $fileParameters = @{
            Encoding = $Encoding
            Path     = $targetPath
            Force    = $Force
        }
        Write-DebugMessage "Using the following parameters when writing to file:"
        Write-DebugMessage ($fileParameters | Out-String)
    }

    process {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Creating file content in memory"
        $fileContent = @()
        $keysWithoutSection = @()
        $sections = @()

        $outKeyParam = @{
            Delimiter             = $delimiter
            IgnoreComments        = $IgnoreComments
            CommentChar           = $CommentChar
            SkipTrailingEqualSign = $SkipTrailingEqualSign
        }

        # A value that is a dictionary is a section. Any other value is a key
        # without a section, like the `$script:NoSection` section Import-Ini creates.
        # Keys without a section must come before the first section header,
        # otherwise they would be read back as part of that section.
        foreach ($entry in $InputObject.GetEnumerator()) {
            if ($entry.Value -isnot [System.Collections.IDictionary]) {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key without section: $($entry.Key)"
                $keysWithoutSection += Out-Key @outKeyParam -InputObject @{ $entry.Key = $entry.Value }
            }
            elseif ($entry.Key -eq $script:NoSection) {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing keys without section"
                $keysWithoutSection += Out-Key @outKeyParam -InputObject $entry.Value
            }
            else {
                $sections += $entry
            }
        }

        if ($keysWithoutSection.Count) {
            $fileContent += $keysWithoutSection

            # Separate Sections with whiteSpace
            if ($Format -eq "pretty") { $fileContent += "" }
        }

        foreach ($section in $sections) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$($section.Key)]"

            $fileContent += "[$($section.Key)]"
            $fileContent += Out-Key @outKeyParam -InputObject $section.Value

            # Separate Sections with whiteSpace
            if ($Format -eq "pretty") { $fileContent += "" }
        }

        $path = if ($LiteralPath) { $LiteralPath } else { $FilePath }
        $resolvedPath = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)

        # When several dictionaries are piped in, append every one after the first,
        # instead of replacing the file each time.
        $appendToFile = $Append -or $writtenPaths.Contains($resolvedPath)

        if ($PSCmdlet.ShouldProcess((Split-Path $path -Leaf), "Write")) {
            # Keys without a section can't be placed before the sections that are already in the file.
            if ($appendToFile -and $keysWithoutSection.Count -and (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
                $existingSection = Get-Content -LiteralPath $resolvedPath -Encoding $Encoding |
                    Where-Object { $_ -match $sectionRegex } |
                    Select-Object -First 1
                if ($existingSection) {
                    Write-Warning "Appending keys without a section to '$path', which already contains sections. Import-Ini will read these keys as part of the last section."
                }
            }

            Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $path"
            $ofsplat = @{
                InputObject   = $fileContent
                NoClobber     = $NoClobber
                Append        = $appendToFile
                Encoding      = $Encoding
                Force         = $Force
                ErrorVariable = "writeError"
            }
            if ($LiteralPath) {
                Microsoft.PowerShell.Utility\Out-File @ofsplat -LiteralPath $LiteralPath
            }
            else {
                Microsoft.PowerShell.Utility\Out-File @ofsplat -FilePath $FilePath
            }

            if (-not $writeError) {
                $null = $writtenPaths.Add($resolvedPath)
            }
        }
    }

    end {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias epini Export-Ini

Register-ArgumentCompleter -CommandName Export-Ini -ParameterName Encoding -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    Get-AllowedEncoding |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_,
                $_,
                [System.Management.Automation.CompletionResultType]::ParameterValue,
                $_
            )
        }
}
