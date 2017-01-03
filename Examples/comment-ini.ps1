# reconstitute a Hashtable from INI file and read a value

$content = Get-IniContent .\settings.ini | Add-IniComment -Sections 'category2' -Keys 'key4'
$content["category2"]["Comment1"]
