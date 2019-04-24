# [PsIni](http://lipkau.github.io/PsIni/)

[![GitHub release](https://img.shields.io/github/release/lipkau/PsIni.svg?style=for-the-badge)](https://github.com/lipkau/PsIni/releases/latest)
[![Build status](https://img.shields.io/appveyor/ci/lipkau/PsIni/master.svg?style=for-the-badge)](https://ci.appveyor.com/project/lipkau/psini/branch/master)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PsIni.svg?style=for-the-badge)](https://www.powershellgallery.com/packages/PsIni)
![License](https://img.shields.io/github/license/lipkau/PsIni.svg?style=for-the-badge)

## Table of Contents

* [Description](#description)
* [Installation](#installation)
* [Examples](#examples)
* [Authors/Contributors](#authorscontributors)

## Description

Work with INI files in PowerShell using hashtables.

### Origin

This code was originally a blog post for [Hey Scripting Guy](http://blogs.technet.com/b/heyscriptingguy)
> [Use PowerShell to Work with Any INI File](http://blogs.technet.com/b/heyscriptingguy/archive/2011/08/20/use-powershell-to-work-with-any-ini-file.aspx)

## Installation

PsIni is published to the [Powershell Gallery](https://www.powershellgallery.com/packages/PsIni)
and can be installed as follows:

```powershell
Install-Module PsIni
```

## Examples

Create a hashtable and save it to C:\settings.ini:

```powershell
Import-Module PsIni
$Category1 = @{"Key1"="Value1";"Key2"="Value2"}
$Category2 = @{"Key1"="Value1";"Key2"="Value2"}
$NewINIContent = @{"Category1"=$Category1;"Category2"=$Category2}
Out-IniFile -InputObject $NewINIContent -FilePath "C:\settings.ini"
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

Returns the key "Key2" of the section "Category2" from the C:\settings.ini file:

```powershell
$FileContent = Get-IniContent "C:\settings.ini"
$FileContent["Category2"]["Key2"]
```

## Authors/Contributors

### Author

* [Oliver Lipkau](https://github.com/lipkau)

### Contributor

* [Craig Buchanan](https://github.com/craibuc)
* [Colin Bate](https://github.com/colinbate)
* [Sean Seymour](https://github.com/seanjseymour)
* [Alexis Côté](https://github.com/popojargo)
* [Konstantin Heil](https://github.com/heilkn)
* [SeverinLeonhardt](https://github.com/SeverinLeonhardt)
* [davidhayesbc](https://github.com/davidhayesbc)
