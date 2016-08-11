# reconstitute a Hashtable from INI file and read a value

$content = Get-IniContent .\settings.ini | Update-IniContent -Sections 'category2' -NameValuePairs 'key4=newvalue4'
$content["category2"]["key4"]
