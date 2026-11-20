# Migrating from PSIni v3 to v4

PSIni v4 introduces several breaking changes and enhancements.
This guide will help you migrate your scripts from v3 to v4.

## Breaking Changes

### 1. Command Renaming

The most significant change in v4 is the renaming of the core commands:

| v3 Command       | v4 Command   | Description                          |
| ---------------- | ------------ | ------------------------------------ |
| `Get-IniContent` | `Import-Ini` | Load INI files into PowerShell       |
| `Out-IniFile`    | `Export-Ini` | Save PowerShell objects to INI files |

Update your scripts by replacing:

```powershell
# Old v3 way
$content = Get-IniContent -Path "config.ini"
$content | Out-IniFile -FilePath "config.new.ini"

# New v4 way
$content = Import-Ini -Path "config.ini"
$content | Export-Ini -Path "config.new.ini"
```

### 2. Handling of Quotation Marks

v4 changes how quotation marks around INI values are handled, as documented in [ADR #95](https://github.com/lipkau/PSIni/discussions/95).

In v4, quotation marks are no longer automatically interpreted or stripped.
This ensures better compatibility with more INI implementations.

```ini
; Example INI content
[Section]
key1=value1
key2="value2"
```

```powershell
# In v3
$content = Get-IniContent "config.ini"
$content["Section"]["key2"] # Returns: value2 (quotation marks were stripped)

# In v4
$content = Import-Ini "config.ini"
$content["Section"]["key2"] # Returns: "value2" (quotation marks are preserved)
```

## New Features

### 1. Improved Error Handling

v4 provides more robust error handling and clearer error messages.

### 2. New Parameters

#### Import-Ini

- `-IgnoreEmptySection`: Ignore empty sections in INI files
- `-LiteralPath`: Handle file paths with special characters
- `-Encoding`: Specify file encoding
- `-InputString`: Parse INI content directly from a string

#### Export-Ini

- `-CommentChar`: Specify comment character

## PowerShell Version Requirements

PSIni v4 requires PowerShell 5.0 or higher. Support for PowerShell v2, v3, and v4 has been removed.

## Migration Steps

1. Update your module:

   ```powershell
   Update-Module -Name PSIni
   # or
   Install-Module -Name PSIni -Scope CurrentUser -Force
   ```

2. Update your scripts:
   - Replace `Get-IniContent` with `Import-Ini`
   - Replace `Out-IniFile` with `Export-Ini`

3. Test your scripts with the new version:
   - Pay special attention to code that relies on quotation mark handling
   - Update parameter names and use new parameters where appropriate

4. If you need to handle quoted values specifically, you may need to add additional logic:

   ```powershell
   # Remove surrounding quotes if necessary
   $value = $content["Section"]["key2"] -replace '^"(.*)"$', '$1'
   ```

## Example Migration

### Before (v3)

```powershell
# Create a hashtable
$Category1 = @{"Key1"="Value1";"Key2"='"Value2"'}
$Category2 = @{"Key1"="Value1";"Key2"='"Value2"'}
$NewINIContent = @{"Category1"=$Category1;"Category2"=$Category2}

# Write to INI file
Out-IniFile -InputObject $NewINIContent -FilePath ".\settings.ini"

# Read from INI file
$FileContent = Get-IniContent ".\settings.ini"
$value = $FileContent["Category1"]["Key2"]  # Value2 (quotes stripped)
```

### After (v4)

```powershell
# Create a hashtable
$Category1 = @{"Key1"="Value1";"Key2"='"Value2"'}
$Category2 = @{"Key1"="Value1";"Key2"='"Value2"'}
$NewINIContent = @{"Category1"=$Category1;"Category2"=$Category2}

# Write to INI file
Export-Ini -InputObject $NewINIContent -Path ".\settings.ini"

# Read from INI file
$FileContent = Import-Ini -Path ".\settings.ini"
$value = $FileContent["Category1"]["Key2"]  # "Value2" (quotes preserved)

# If you need to strip quotes manually
$valueWithoutQuotes = $value -replace '^"(.*)"$', '$1'
```

## Additional Resources

- [Full Changelog for v4.0.0](https://github.com/lipkau/PSIni/blob/master/CHANGELOG.md)
- [ADR #95: Handling quotes around values](https://github.com/lipkau/PSIni/discussions/95)
