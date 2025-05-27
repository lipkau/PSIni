function Export-Ini {
    <#
    .Synopsis
        Write hash content to INI file

    .Description
        Write hash content to INI file

    .Inputs
        System.String
        System.Collections.IDictionary

    .Example
        Export-Ini $IniVar "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini

    .Example
        $IniVar | Export-Ini "C:\myinifile.ini" -Force
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present

    .Example
        $file = Export-Ini $IniVar -FilePath "C:\myinifile.ini" -PassThru
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file. Writes exported data to console, as a powershell object.

    .Example
        $Category1 = @{"Key1"="Value1";"Key2"="Value2"}
        $Category2 = @{"Key1"="Value1";"Key2"="Value2"}
        $NewINIContent = @{"Category1"=$Category1;"Category2"=$Category2}
        Export-Ini -InputObject $NewINIContent -FilePath "C:\MyNewFile.ini"
        -----------
        Description
        Creating a custom Hashtable and saving it to C:\MyNewFile.ini

    .Example
        $Winpeshl = @{
            LaunchApp = @{
                AppPath = %"SYSTEMDRIVE%\Fabrikam\shell.exe"
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
        ConvertFrom-Ini
        ConvertTo-Ini
    #>

    [CmdletBinding( SupportsShouldProcess )]
    [OutputType( [Void] )]
    param(
        # Specifies the Hashtable to be written to the file.
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
        # This behavior is needed for specific OS files, such as:
        # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpeshlini-reference-launching-an-app-when-winpe-starts
        [Parameter()]
        [Switch]
        $SkipTrailingEqualSign
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $delimiter = if ($Format -eq "pretty") { ' = ' } else { '=' }

        $fileParameters = @{
            Encoding = $Encoding
            Path     = $Path
            Force    = $Force
        }
        Write-DebugMessage "Using the following parameters when writing to file:"
        Write-DebugMessage ($fileParameters | Out-String)
    }

    process {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Creating file content in memory"
        $fileContent = @()

        foreach ($section in $InputObject.GetEnumerator().Name) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$section]"

            # Add section header to the content array
            # Note: this relies on an OrderedDictionary for the keys without a section to be at the top of the file
            if ($section -ne $script:NoSection) {
                $fileContent += "[$section]"
            }

            $outKeyParam = @{
                InputObject           = $InputObject[$section]
                Delimiter             = $delimiter
                IgnoreComments        = $IgnoreComments
                CommentChar           = $CommentChar
                SkipTrailingEqualSign = $SkipTrailingEqualSign
            }
            $fileContent += Out-Key @outKeyParam

            # TODO: what when the Input is only a simple hash?

            # Separate Sections with whiteSpace
            if ($Format -eq "pretty") { $fileContent += "" }
        }

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Path"
        $ofsplat = @{
            InputObject = $fileContent
            NoClobber   = $NoClobber
            Append      = $Append
            Encoding    = $Encoding
        }
        if ($LiteralPath) {
            if ($PSCmdlet.ShouldProcess((Split-Path $LiteralPath -Leaf), "Write")) {
                Out-File @ofsplat -LiteralPath $LiteralPath
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess((Split-Path $FilePath -Leaf), "Write")) {
                Out-File @ofsplat -FilePath $FilePath
            }
        }
    }

    end {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias epini Export-Ini

Register-ArgumentCompleter -CommandName Export-Ini -ParameterName Encoding -ScriptBlock {
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
