# reconstitute a Hashtable from INI file and read a value

$content = Get-IniContent .\settings.ini | Remove-IniEntry -Sections 'category2' -Keys 'key4'
if (!$content["category2"]["key4"]) { Write-Host "content[category2][key4] no longer exists." }
