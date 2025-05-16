# PSIni Examples

This directory contains examples demonstrating how to use the PSIni module to work with INI files.

## Getting Started

All examples assume the PSIni module is already installed. If not, you can install it with:

```powershell
Install-Module -Name PSIni -Scope CurrentUser
```

## Example Files

### Basic Operations

- **[read-ini.ps1](read-ini.ps1)**: Demonstrates how to read INI files and access their content
- **[save-ini.ps1](save-ini.ps1)**: Shows how to create and save INI files
- **[update-ini.ps1](update-ini.ps1)**: Examples of updating existing keys and adding new keys
- **[remove-ini.ps1](remove-ini.ps1)**: Demonstrates how to remove keys and sections

### Advanced Features

- **[arrays.ps1](arrays.ps1)**: Working with array values in INI files
- **[comment-ini.ps1](comment-ini.ps1)**: Adding and working with comments
- **[uncomment-ini.ps1](uncomment-ini.ps1)**: Converting comments back to regular key-value pairs
- **[handle-quotes.ps1](handle-quotes.ps1)**: Managing quotation marks in INI values (v4 behavior)
- **[new-features-v4.ps1](new-features-v4.ps1)**: Demonstrates new features in v4 like InputString, IgnoreEmptySection, etc.
- **[command-line-parsing.ps1](command-line-parsing.ps1)**: Parsing INI content directly from strings without files

### Comprehensive Examples

- **[full-example.ps1](full-example.ps1)**: A comprehensive example showing the complete workflow of creating, reading, modifying, and saving INI files

## Sample Files

- **[settings.ini](settings.ini)**: A sample INI file used by many of the examples
- Other generated INI files will be created when running the examples

## Usage

To run an example, navigate to this directory and execute the desired script:

```powershell
cd /path/to/PSIni/Examples
./read-ini.ps1
```

## Notes on v4 Changes

PSIni v4 introduced some breaking changes and new features compared to v3:

- Commands were renamed: `Get-IniContent` → `Import-Ini` and `Out-IniFile` → `Export-Ini`
- Quotation marks are no longer stripped from values by default
- New parameters were added like `-InputString`, `-IgnoreEmptySection`, `-CommentChar`, etc.

For more details on migrating from v3, see the [migration guide](../docs/Migrating-to-v4.md).
