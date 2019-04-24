# Thanks to mklement0
# https://stackoverflow.com/a/55341293/8176975


# Import the PsIni module.
# If necessary, install it first, for the current user.
$ErrorActionPreference = 'Stop' # Abort, if something unexpectedly goes wrong.
try {
    Import-Module PsIni
}
catch {
    Install-Module -Scope CurrentUser PsIni
    Import-Module PsIni
}

# Create an ordered hashtable that is the in-memory representation of the
# sample *.ini file from the question, with a second section added.
$iniFileContent = [ordered] @{
    # 'XXX' is the section name.
    # The nested hashtable contains that section's entries.
    XXX = [ordered] @{
        # IMPORTANT:
        #  * The PsIni module only supports STRING values.
        #  * While you can assign values of different types in-memory, they are
        #    CONVERTED TO STRINGS with .ToString() and READ AS STRINGS later
        #    by Get-IniContent.
        #  * In v3+, PSIni now supports values in *.ini files that have
        #    embedded quoting - e.g., `AB = "23"` as a raw line - which is
        #    (sensibly) *stripped* on reading the values.
        AB = '23'
        BC = '34'
    }
    # Create a 2nd section, named 'YYY', with entries 'yin' and 'yang'
    YYY = [ordered] @{
        yin  = 'foo'
        yang = 'none'
    }
}

# Use Out-IniFile to create file 'file.ini' in the current dir.
# * Default encoding is UTF-8 (with BOM in Windows PowerShell, without BOM
#   in PowerShell Core)
# * Use -Encoding to override, but note that
#   Get-IniContent has no matching -Encoding parameter, so the encoding you use
#   must be detectable by PowerShell in the absence of explicit information.
# * CAVEAT: -Force is only needed if an existing file must be overwritten.
#           I'm using it here so you can run the sample code repeatedly without
#           failure, but in general you should only use it if you want to
#           blindly replace an existing file - such as after having modified
#           the in-memory representation of an *.ini file and wanting to
#           write the modifications back to disk - see below.
$iniFileContent | Out-IniFile -Force file.ini

# Read the file back into a (new) ordered hashtable
$iniFileContent = Get-IniContent file.ini

# Modify the value of the [XXX] section's 'AB' entry.
$iniFileContent.XXX.AB = '12'

# Use the alternative *indexing syntax* (which is equivalent in most cases)
# to also modify the [YYY] section's 'yin' entry.
$iniFileContent['YYY']['yin'] = 'bar'

# Rmove the 'yang' value from section [YYY]:
$iniFileContent.YYY.Remove('yang')

# Save the modified content back to the original file.
# Note that -Force is now *required* to signal the explicit intent to
# replace the existing file.
$iniFileContent | Out-IniFile -Force file.ini

# Double-check that modifying the values succeeded.
(Get-IniContent file.ini).XXX.AB # should output '12'
(Get-IniContent file.ini).YYY.yin # should output 'bar'

# Print the updated content of the INI file, which
# shows the updated values and the removal of 'yang' from [YYY].
"--- Contents of file.ini:"
Get-Content file.ini
