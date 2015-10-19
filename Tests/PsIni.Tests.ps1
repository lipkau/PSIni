# Enforce WorkingDir
#--------------------------------------------------
$Script:ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Set-Location $ScriptDir

# Module Env
#--------------------------------------------------
$Script:paths = @($env:PSModulePath -split ';')
$ModuleRoot = (Resolve-Path "$ScriptDir\..\..").Path
if (!($Script:paths -contains $ModuleRoot))
{
    $Script:paths += $ModuleRoot
}
$env:PSModulePath = $Script:paths -join ';'

Describe "PsIni" {

    # arrange
    $iniFile = "TestDrive:\Settings.ini"

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
        Import-Module "PsIni" -Force -ErrorAction SilentlyContinue

        #assert
        It "loads the module" {
            $error.count | Should Be 0
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