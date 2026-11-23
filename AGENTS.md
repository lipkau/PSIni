# AGENTS.md

This file gives coding agents the guidance they need to work in this repository.

PSIni is a PowerShell module that reads INI files into dictionaries (`Import-Ini`) and writes dictionaries to INI files (`Export-Ini`).
It supports Windows PowerShell 5.1 and PowerShell 7. CI runs the tests on Windows PowerShell 5.1 and on PowerShell 7 on Windows, Linux and macOS.

## Commands

Install the build dependencies once. Their versions are pinned in `tools/build.requirements.psd1`:

```powershell
./tools/setup.ps1
```

| Command | What it does |
| --- | --- |
| `Invoke-Build` | Clean, Build and Test |
| `Invoke-Build -Task Build` | Compile the module into `release/` |
| `Invoke-Build -Task Test` | Run every Pester test against `release/` |
| `Invoke-Build -Task Test -PesterVerbosity Detailed` | The same, listing every test |
| `Invoke-Pester -Path Tests/Export-Ini.Unit.Tests.ps1 -FullNameFilter '*empty section*'` | Run one file or matching tests against the source in `PSIni/`, no build needed |
| `./tools/update.dependencies.ps1` | Raise the pinned build dependencies to their latest PSGallery versions |

`Invoke-Build -Task Test` runs the copy of `Tests/` that Build made in `release/Tests`. After you change source or tests, run Build again (or plain `Invoke-Build`), or you test the old code.
`Invoke-Pester` needs Pester 6.2, the version `setup.ps1` installs.

PSScriptAnalyzer runs as part of the tests (`Tests/PSScriptAnalyzer.Tests.ps1`), with the rules in `PSScriptAnalyzerSettings.psd1`.

## How the module is put together

- `PSIni/PSIni.psm1` dot-sources every file in `Public/` and `Private/` and exports the public functions. The Build task compiles all of them into one `release/PSIni/PSIni.psm1`. It keeps only the `#region Configuration` and `#region Dependencies` blocks of the source `.psm1`, so module-level variables must live inside one of those regions.
- `Tests/Helpers/Resolve-ModuleSource.ps1` chooses what the tests import: the built module when the tests run from `release/Tests` under Invoke-Build, otherwise `PSIni/PSIni.psd1`.
- The data model shared by `Import-Ini` and `Export-Ini`:
  - The result is an `OrderedDictionary` (case-insensitive) of sections. Each section is an `OrderedDictionary` of keys.
  - Keys before the first section are stored under the section `_` (`$script:NoSection`).
  - Comments are stored as keys `__Comment1`, `__Comment2`, … (`$script:CommentPrefix`), numbered per section.
  - A key that appears more than once holds an `ArrayList` of its values. A key without `=` holds `$null`; `key=` holds `''`.
  - Any change to this model has to be made in both directions, so that a round trip `Import-Ini` → `Export-Ini` keeps the file.
- `Private/Out-Key.ps1` writes the lines of one section, for `Export-Ini`.
- `-Encoding` accepts different values in Windows PowerShell 5.1 and PowerShell 7. `Private/Get-AllowedEncoding.ps1` reads them from the built-in `Out-File`. `Export-Ini` calls `Microsoft.PowerShell.Utility\Out-File` by its full name, so another module's `Out-File` can't replace it.

## Rules the tests enforce

- Every public function has a `Tests/<Name>.Unit.Tests.ps1` file, and every file in `Public/` is exported.
- Comment-based help needs a synopsis, a description, and at least one example per parameter set. Every example needs a description, and every parameter needs a help comment.
- Source files have no trailing whitespace and end with a newline.
- `ModuleVersion` in `PSIni/PSIni.psd1` only has major and minor (`4.0`). The release workflow sets the full version from the git tag. Don't change it in a PR.

## Files

- `.ps1`, `.psm1` and `.psd1` files use CRLF line endings (`.gitattributes`, `.editorconfig`). Most start with a UTF-8 BOM, so keep the BOM a file already has. Windows PowerShell 5.1 reads a file without a BOM as ANSI. Everything else uses LF.
- Code style is Stroustrup braces with 4-space indents, checked by PSScriptAnalyzer. Write full cmdlet and parameter names, not aliases or positional arguments.

## Changelog and documentation

Every PR that changes behavior updates its own documentation in the same PR:

- an entry in `CHANGELOG.md` under `## [NEXT VERSION]`, in `### Added`, `### Fixed`, `### Changed` or `### Removed`, in the form `* Fixed <what> @<author> #<PR>`. When behavior changes, say what users should check.
- the comment-based help of the functions it touches, plus `README.md`, `docs/` or `Examples/` when they describe the changed behavior.

Don't leave the changelog or docs for a separate release-notes task. The release task only renames `[NEXT VERSION]` to the version and date.
The one exception is the v4.1 milestone: its notes are still collected in [#176](https://github.com/lipkau/PSIni/issues/176). That task removes this paragraph.
