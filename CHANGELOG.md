<!-- markdownlint-disable MD024 -->
# Changelog

## [NEXT VERSION] - YYYY-MM-DD

`v4` is a breaking change, as the Commands of the module were refactored and renamed.\
Details on how to upgrade are documented in the [Migrating to PSIni v4](#TODO: )

### Added

* Add -IgnoreEmptySection parameter to `Import-Ini` @kevinholtkamp #69
* Added `ConvertFrom-Ini` @lipkau
* Added `ConvertTo-Ini` @lipkau

### Fixed

* No longer reading empty lines as keys  @HighPriest #79
* Improve performance by operating in-memory @HighPriest #80
* Fix tests for ending empty line behaviour in pretty print @HighPriest #90

### Changed

* ***BREAKING**: `Get-IniContent` is replaced with `Import-Ini` @lipkau
* ***BREAKING**: `Out-IniFile` is replaced with `Export-Ini` @lipkau

### Removed

* Removed support for Powershell v2, v3 and v4 @lipkau

## v3 - 2019-03-23

_This is a collection of changes in `v3.*`._

PR#42 caused a breaking change, as the change to the quotations marks could result in a different behaviour than current users are accustomed to.

### Added

* Allow whitespaces in the beginning of comments @ildar-shaimordanov #42
* Allow whitespaces around sections and key/value/pairs @ildar-shaimordanov #42
* Allow quotation for values @ildar-shaimordanov #42
* Move the important regexp settings out of the `Process` block @ildar-shaimordanov #42

### Fixed

### Changed

* Removed behaviour to create a nested `arraylist` on the first item when keynames are the same. Which caused the first items to be doubled up into two lists. @tcartwright #73

### Removed

## v2 - 2018-01-22

_This is a collection of changes in `v2.*`._

Issue#37 identified a breaking change from `v1.*`.

### Added

* Added parameter `-Pretty` for writing Ini files @lipkau #39
* Read Multiple Values for Common Key into Array @heilkn #43

### Fixed

* Fixed parameter property declaration for Powershell v2 compatibility @lipkau #41
* Fixed backwards compatibility: Values should only be of type `[array]` when necessary; `[string]` otherwise @lipkau
* Fix random `Add-Content : Stream was not readable` error @michaelPf85 #44

### Changed

### Removed

* Removed Strict Mode @lipkau #45

## v1 - 2010-03-12

_This is a collection of changes in `v1.*`._

It was first published on the [Microsoft Script Gallery](http://gallery.technet.microsoft.com/scriptcenter/):\
<http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91>

It was published on the [Hey Scripting Guy Blog](https://devblogs.microsoft.com/scripting/) on 2011-08-20:\
[Use PowerShell to Work with Any INI File](https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/)

### Added

* Added unit tests. @craibuc #3
* Use `OrderedDictionary`, support `#` comments, utf8 by default and better round tripping. @colinbate #7
* Accepts whitespaces in `[section]` line of INI file @lipkau #22
* Add Comment, Uncomment, Remove and Update functions @seanjseymour #24
* Support empty sections @popojargo #27

### Fixed

* Bugfix/Added example to help @IngmarVerheij
* Improved handling for missing output file @SLDR
* Fixed typos @SLDR & @DaveStiff
* Fixed parameters in nested function @lipkau
* Bug `Out-IniFile`: `$delimiter` misspelt as `$equal` @jpaugh #32
* Fix accessing dictionary keys @SeverinLeonhardt #36

### Changed

* Improvment to switch @Tallandtree
* Migrate to semantic versioning @lipkau #4
* Changed .outputs section to be `OrderedDictionary` @craibuc #15

### Removed

* Removed need for delimiters by making Sections a string array and NameValuePairs a hashtable
* Removed extra `\r\n` at end of file @craibuc
* Remove check for `.ini` extension @lipkau #6
* Remove the need for delimiters from certain parameters @seanjseymour #31
