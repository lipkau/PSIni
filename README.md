# [PSIni](http://lipkau.github.io/PSIni/)

[![GitHub release](https://img.shields.io/github/release/lipkau/PSIni.svg?style=for-the-badge)](https://github.com/lipkau/PSIni/releases/latest)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/lipkau/PSIni/build_and_test.yml?branch=master&style=for-the-badge)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSIni.svg?style=for-the-badge)](https://www.powershellgallery.com/packages/PSIni)
![License](https://img.shields.io/github/license/lipkau/PSIni.svg?style=for-the-badge)

## Table of Contents

- [PSIni](#psini)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
    - [Origin](#origin)
  - [Installation](#installation)
  - [Examples](#examples)
    - [Create INI file from hashtable](#create-ini-file-from-hashtable)
    - [Read the content of an INI file](#read-the-content-of-an-ini-file)
  - [Contributors](#contributors)

## Description

Work with INI files in PowerShell using hashtables.

### Origin

This code was originally a blog post for [Hey Scripting Guy](https://devblogs.microsoft.com/scripting/).
> [Use PowerShell to Work with Any INI File](https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/)

Over time this project got a lot of enhancements and major face-lifts.

## Installation

PSIni is published to the [Powershell Gallery](https://www.powershellgallery.com/packages/PSIni)
and can be installed as follows:

```powershell
Install-Module PSIni <# -Scope User #>
```

---

When using the source (this repository), you can easily get the necessary setup by running

```powershell
. ./tools/setup.ps1
```

_Additional information can be found in [CONTRIBUTING](CONTRIBUTING.md)._

## Examples

### Create INI file from hashtable

Create a hashtable and save it to `./settings.ini`:

```powershell
$Category1 = @{"Key1"="Value1";"Key2"="Value2"}
$Category2 = @{"Key1"="Value1";"Key2"="Value2"}
$NewINIContent = @{"Category1"=$Category1;"Category2"=$Category2}

Import-Module PSIni
Out-IniFile -InputObject $NewINIContent -FilePath ".\settings.ini"
```

Results:

> ```Ini
> [Category1]
> Key1=Value1
> Key2=Value2
>
> [Category2]
> Key1=Value1
> Key2=Value2
> ```

### Read the content of an INI file

Returns the key "Key2" of the section "Category2" from the `./settings.ini` file:

```powershell
$FileContent = Get-IniContent "C:\settings.ini"
$FileContent["Category2"]["Key2"]
```

## Contributors

This project benefited immensely from the contribution of powershell enthusiasts.
Thank you ❤️

The Contributors: <https://github.com/lipkau/PSIni/graphs/contributors>
