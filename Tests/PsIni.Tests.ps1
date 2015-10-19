# Enforce WorkingDir
#--------------------------------------------------
$Script:ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Set-Location $ScriptDir

$manifestPath   = "$ScriptDir\..\PsIni.psd1"

Describe -Tags 'VersionChecks' "PsIni manifest" {
    $script:manifest = $null
    It "has a valid manifest" {
        {
            $script:manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop -WarningAction SilentlyContinue
        } | Should Not Throw
    }

    It "has a valid name in the manifest" {
        $script:manifest.Name | Should Be PsIni
    }

    It "has a valid guid in the manifest" {
        $script:manifest.Guid | Should Be '98e1dc0f-2f03-4ca1-98bb-fd7b4b6ac652'
    }

    It "has a valid version in the manifest" {
        $script:manifest.Version -as [Version] | Should Not BeNullOrEmpty
    }

    # if (Get-Command git.exe -ErrorAction SilentlyContinue) {
    #     $script:tagVersion = $null
    #     It "is tagged with a valid version" {
    #         $thisCommit = git.exe log --decorate --oneline HEAD~1..HEAD

    #         if ($thisCommit -match 'tag:\s*(\d+(?:\.\d+)*)')
    #         {
    #             $script:tagVersion = $matches[1]
    #         }

    #         $script:tagVersion                  | Should Not BeNullOrEmpty
    #         $script:tagVersion -as [Version]    | Should Not BeNullOrEmpty
    #     }

    #     It "all versions are the same" {
    #         $script:manifest.Version -as [Version] | Should be ( $script:tagVersion -as [Version] )
    #     }

    # }
}

Describe "PsIni functionality" {

    # arrange
    $iniFile = "$TestDrive\Settings.ini"

    # values to be persisted
    $dictIn = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
    $dictIn["Category1"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
    $dictIn["Category1"]["Key1"] = "Value1"
    $dictIn["Category1"]["Key2"] = "Value2"
    $dictIn["Category2"] = New-Object System.Collections.Specialized.OrderedDictionary([System.StringComparer]::OrdinalIgnoreCase)
    $dictIn["Category2"]["Key3"] = "Value3"
    $dictIn["Category2"]["Key4"] = "Value4"

    Context "Load Module" {

        #act
        $error.clear()
        Import-Module "$ScriptDir\..\..\PsIni" -Force -ErrorAction SilentlyContinue

        #assert
        It "loads the module" {
            $error.count #| Should Be 0
        }

    }

    Context "Writing INI" {

        # act
        $dictIn | Out-IniFile -FilePath $iniFile

        # assert
        It "creates a file" {
            # should exist
            Test-Path $iniFile | Should Be $true
        }

        # assert
        It "content matches expected value" {

            $content = "[Category1]`r`nKey1=value1`r`nKey2=Value2`r`n`r`n[Category2]`r`nKey3=Value3`r`nKey4=Value4`r`n`r`n"

            # http://powershell.org/wp/2013/10/21/why-get-content-aint-yer-friend
            Get-Content $iniFile | Out-String | Should Be $content

        }

    }

    Context "Reading INI" {

        # act
        Out-IniFile -InputObject $dictIn -FilePath $iniFile
        $dictOut = Get-IniContent -FilePath $iniFile

        # assert
        It "creates a OrderedDictionary from an INI file" {
            ($dictOut.GetType()) | Should Be System.Collections.Specialized.OrderedDictionary
        }

        # assert
        It "content matches original hashtable" {
            Compare-Object $dictIn $dictOut
        }

    }

}

Describe 'Style rules' {
    $psiniRoot = (Get-Module PsIni).ModuleBase

    $files = @(
        Get-ChildItem $psiniRoot -Include *.ps1,*.psm1
        Get-ChildItem $psiniRoot\Functions -Include *.ps1,*.psm1 -Recurse
    )

    It 'PsIni source files contain no trailing whitespace' {
        $badLines = @(
            foreach ($file in $files)
            {
                $lines = [System.IO.File]::ReadAllLines($file.FullName)
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++)
                {
                    if ($lines[$i] -match '\s+$')
                    {
                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                    }
                }
            }
        )

        if ($badLines.Count -gt 0)
        {
            throw "The following $($badLines.Count) lines contain trailing whitespace: `r`n`r`n$($badLines -join "`r`n")"
        }
    }

    It 'PsIni Source Files all end with a newline' {
        $badFiles = @(
            foreach ($file in $files)
            {
                $string = [System.IO.File]::ReadAllText($file.FullName)
                if ($string.Length -gt 0 -and $string[-1] -ne "`n")
                {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0)
        {
            throw "The following files do not end with a newline: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }
}
