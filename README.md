# [PSIni](http://lipkau.github.io/PSIni/)

[![GitHub release](https://img.shields.io/github/release/lipkau/PSIni.svg?style=for-the-badge)](https://github.com/lipkau/PSIni/releases/latest)
[![Build status](https://img.shields.io/appveyor/ci/lipkau/PSIni/master.svg?style=for-the-badge)](https://ci.appveyor.com/project/lipkau/psini/branch/master)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSIni.svg?style=for-the-badge)](https://www.powershellgallery.com/packages/PSIni)
![License](https://img.shields.io/github/license/lipkau/PSIni.svg?style=for-the-badge)

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

PSIni is published to the [Powershell Gallery](https://www.powershellgallery.com/packages/PSIni)
and can be installed as follows:

```powershell
Install-Module PSIni
```

## Examples

Create a hashtable and save it to C:\settings.ini:

```powershell
Import-Module PSIni
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
