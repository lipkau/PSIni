#requires -Version 5

function ConvertFrom-Ini {
    <#
    .Synopsis
        Transform the content of an INI file to a Powershell object

    .Description
        The output of reading an INI file is an object of type [OrderedDictionary].
        This object is similar to a HashTable.
        By using this cmdlet, you can transform it to a normal Powershell object [PSCustomObject]

    .Example
        Import-Ini -path ".\config.ini" | ConvertFrom-Ini
        -----------
        Description
        Will use the output of `Import-Ini` and convert it to a powershell object

    .Example
        ConvertFrom-Ini -Path (Get-ChildItem *.ini)
        -----------
        Description
        Will output the content of all ini files in the current path as powershell objects

    .Link
        ConvertFrom-ini
        Import-Ini
        Export-Ini
    #>
    [CmdletBinding( DefaultParameterSetName = 'byObject' )]
    [OutputType( [PSCustomObject] )]
    param(
        # Dictionary describing an INI file
        [Parameter( Mandatory, ValueFromPipeline, ParameterSetName = 'byObject' )]
        [System.Collections.Specialized.OrderedDictionary]
        $InputObject,

        # Path to an INI file
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'fromFile' )]
        [ValidateNotNullOrEmpty()]
        [Alias("PSPath", "FullName")]
        [String[]]
        $Path
    )

    begin {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
    }

    process {
        switch ($PsCmdLet.ParameterSetName) {
            'fromFile' {
                return Import-Ini -Path $Path | ConvertFrom-Ini
            }
            'byObject' {
                $r = @{ }

                foreach ($section in $InputObject.Keys) {
                    if ($section -eq $script:NoSection) {
                        foreach ($key in $InputObject[$section].Keys) {
                            $r[$key] = $InputObject[$section][$key]
                        }
                    }
                    else {
                        $r[$section] = [PSCustomObject]$InputObject[$section]
                    }
                }

                return [PSCustomObject]$r
            }
        }
    }

    end {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}
