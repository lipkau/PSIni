﻿function Export-Ini {
    <#
    .Synopsis
        Write hash content to INI file

    .Description
        Write hash content to INI file

    .Inputs
        System.String
        System.Collections.IDictionary

    .Outputs
        System.IO.FileSystemInfo

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
        $file = Export-Ini $IniVar "C:\myinifile.ini" -PassThru
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

    [CmdletBinding()]
    [OutputType( [System.IO.FileSystemInfo] )]
    param(
        # Specifies the Hashtable to be written to the file.
        # Enter a variable that contains the objects or type a command or expression that gets the objects.
        [Parameter( Mandatory, ValueFromPipeline )]
        [System.Collections.IDictionary]
        $InputObject,

        # Specifies the path to the output file.
        [Parameter( Mandatory, Position = 0 )]
        [ValidateScript( { Invoke-ConditionalParameterValidationPath -InputObject $_ } )]
        [String]
        $Path,

        # Adds the output to the end of an existing file, instead of replacing the file contents.
        [Switch]
        $Append,

        # Specifies the file encoding.
        # The default is UTF8.
        [Parameter()]
        [ValidateScript( { Invoke-ConditionalParameterValidationEncoding -InputObject $_ } )]
        [String]
        $Encoding = "UTF8",

        # Allows the cmdlet to overwrite an existing read-only file.
        # Even using the Force parameter, the cmdlet cannot override security restrictions.
        [Parameter()]
        [Switch]
        $Force,

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

        # Passes an object representing the location to the pipeline.
        # By default, this cmdlet does not generate any output.
        [Parameter()]
        [Switch]
        $Passthru,

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
        $fileContent = @()

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Path"
        foreach ($section in $InputObject.Keys) {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$section]"

            # Add section header to the content array
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

            #Collect output from Out-Key to fileContent
            $fileContent += Out-Key @outKeyParam

            # TODO: what when the Input is only a simple hash?

            if ($Format -eq "pretty") { $fileContent += "" } # Separate Sections with whiteSpace
        }

        Out-File -FilePath $Path -InputObject $fileContent -Encoding $Encoding -Force:$Force -Append:$Append
    }

    end {
        # $PassThru grabs the written file & passes it's identifier into stdout
        if ($PassThru) { Get-Item -Path $Path }

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
