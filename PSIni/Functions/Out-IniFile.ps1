Set-StrictMode -Version Latest
Function Out-IniFile {
    <#
    .Synopsis
        Write hash content to INI file

    .Description
        Write hash content to INI file

    .Notes
        Author      : Oliver Lipkau <oliver@lipkau.net>
        Blog        : http://oliver.lipkau.net/blog/
        Source      : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version     : 1.0.0 - 2010/03/12 - OL - Initial release
                      1.0.1 - 2012/04/19 - OL - Bugfix/Added example to help (Thx Ingmar Verheij)
                      1.0.2 - 2014/12/11 - OL - Improved handling for missing output file (Thx SLDR)
                      1.0.3 - 2014/01/06 - CB - removed extra \r\n at end of file
                      1.0.4 - 2015/06/06 - OL - Typo (Thx Dominik)
                      1.0.5 - 2015/06/18 - OL - Migrate to semantic versioning (GitHub issue#4)
                      1.0.6 - 2015/06/18 - OL - Remove check for .ini extension (GitHub Issue#6)
                      1.1.0 - 2015/07/14 - CB - Improve round-tripping and be a bit more liberal (GitHub Pull #7)
                                           OL - Small Improvments and cleanup
                      1.1.2 - 2015/10/14 - OL - Fixed parameters in nested function
                      1.1.3 - 2016/08/18 - SS - Moved the get/create code for $FilePath to the Process block since it
                                                overwrites files piped in by other functions when it's in the Begin block,
                                                added additional debug output.
                      1.1.4 - 2016/12/29 - SS - Support output of a blank ini, e.g. if all sections got removed. This
                                                required removing [ValidateNotNullOrEmpty()] from InputObject

        #Requires -Version 2.0

    .Inputs
        System.String
        System.Collections.IDictionary

    .Outputs
        System.IO.FileSystemInfo

    .Parameter Append
        Adds the output to the end of an existing file, instead of replacing the file contents.

    .Parameter InputObject
        Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.

    .Parameter FilePath
        Specifies the path to the output file.

     .Parameter Encoding
        Specifies the file encoding. The default is UTF8.

    Valid values are:

    -- ASCII:  Uses the encoding for the ASCII (7-bit) character set.
    -- BigEndianUnicode:  Encodes in UTF-16 format using the big-endian byte order.
    -- Byte:   Encodes a set of characters into a sequence of bytes.
    -- String:  Uses the encoding type for a string.
    -- Unicode:  Encodes in UTF-16 format using the little-endian byte order.
    -- UTF7:   Encodes in UTF-7 format.
    -- UTF8:  Encodes in UTF-8 format.

     .Parameter Force
        Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.

     .Parameter PassThru
        Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

     .Parameter Loose
        Adds spaces around the equal sign when writing the key = value

    .Example
        Out-IniFile $IniVar "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini

    .Example
        $IniVar | Out-IniFile "C:\myinifile.ini" -Force
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present

    .Example
        $file = Out-IniFile $IniVar "C:\myinifile.ini" -PassThru
        -----------
        Description
        Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file

    .Example
        $Category1 = @{“Key1”=”Value1”;”Key2”=”Value2”}
        $Category2 = @{“Key1”=”Value1”;”Key2”=”Value2”}
        $NewINIContent = @{“Category1”=$Category1;”Category2”=$Category2}
        Out-IniFile -InputObject $NewINIContent -FilePath "C:\MyNewFile.ini"
        -----------
        Description
        Creating a custom Hashtable and saving it to C:\MyNewFile.ini
    .Link
        Get-IniContent
    #>

    [CmdletBinding()]
    [OutputType(
        [System.IO.FileSystemInfo]
    )]
    Param(
        [switch]$Append,

        [ValidateSet("Unicode","UTF7","UTF8","ASCII","BigEndianUnicode","Byte","String")]
        [Parameter()]
        [string]$Encoding = "UTF8",

        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -IsValid})]
        [Parameter(Mandatory=$True,
                   Position=0)]
        [string]$FilePath,

        [switch]$Force,

        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [System.Collections.IDictionary]$InputObject,

        [switch]$Passthru,

        [switch]$Loose
    )

    Begin
    {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) { $DebugPreference = 'Continue' }
        Write-Debug "DebugPreference: $DebugPreference"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        function Out-Keys
        {
            param(
                [ValidateNotNullOrEmpty()]
                [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
                [System.Collections.IDictionary]$InputObject,

                [ValidateSet("Unicode","UTF7","UTF8","ASCII","BigEndianUnicode","Byte","String")]
                [Parameter(Mandatory=$True)]
                [string]$Encoding = "UTF8",

                [ValidateNotNullOrEmpty()]
                [ValidateScript({Test-Path $_ -IsValid})]
                [Parameter(Mandatory=$True,
                           ValueFromPipelineByPropertyName=$true)]
                [string]$Path,

                [Parameter(Mandatory=$True)]
                $delimiter,

                [Parameter(Mandatory=$True)]
                $MyInvocation
            )

            Process
            {
                if (!($InputObject.keys))
                {
                    Write-Warning ("No data found in '{0}'." -f $FilePath)
                }
                Foreach ($key in $InputObject.keys)
                {
                    if ($key -match "^Comment\d+") {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $key"
                        Add-Content -Value "$($InputObject[$key])" -Encoding $Encoding -Path $Path
                    } else {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $key"
                        Add-Content -Value "$key$delimiter$($InputObject[$key])" -Encoding $Encoding -Path $Path
                    }
                }
            }
        }

        $delimiter = '='
        if ($Loose)
            { $delimiter = ' = ' }

        #Splatting Parameters
        $parameters = @{
            Encoding     = $Encoding;
            Path         = $FilePath
        }

    }

    Process
    {
        if ($append)
        {
            Write-Debug ("Appending to '{0}'." -f $FilePath)
            $outfile = Get-Item $FilePath
        } else {
            Write-Debug ("Creating new file '{0}'." -f $FilePath)
            $outFile = New-Item -ItemType file -Path $Filepath -Force:$Force
        }

        if (!(Test-Path $outFile.FullName)) {Throw "Could not create File"}

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"
        foreach ($i in $InputObject.keys)
        {
            if (!($InputObject[$i].GetType().GetInterface('IDictionary')))
            {
                #Key value pair
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                Add-Content -Value "$i$delimiter$($InputObject[$i])" @parameters

            } elseif ($i -eq $script:NoSection) {
                #Key value pair of NoSection
                Out-Keys $InputObject[$i] `
                         @parameters `
                         -delimiter $delimiter `
                         -MyInvocation $MyInvocation
            } else {
                #Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"

                # Only write section, if it is not a dummy ($script:NoSection)
                if ($i -ne $script:NoSection) { Add-Content -Value "`n[$i]" @parameters }

                if ( $InputObject[$i].Count) {
                    Out-Keys $InputObject[$i] `
                         @parameters `
                         -delimiter $delimiter `
                         -MyInvocation $MyInvocation
                }

            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $FilePath"
    }

    End
    {
        if ($PassThru)
        {
            Write-Debug ("Returning file due to PassThru argument.")
            Return (Get-Item $outFile)
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}

Set-Alias oif Out-IniFile
