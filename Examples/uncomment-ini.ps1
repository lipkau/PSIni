# reconstitute a Hashtable from INI file and read a value

$category1=@{"key1"="value1";"key2"="value2"}
$category2=@{"key3"="value3";"Comment1"=";key4=value4"}
$content=@{"category1"=$category1;"category2"=$category2}
out-inifile -inputobject $content -filepath .\settings.ini -force

Write-Host("content[category2][key4] is commented out as {0}" -f $content["category2"]["Comment1"])
$content = Get-IniContent .\settings.ini | Remove-IniComment -Sections 'category2' -Keys 'key4'
Write-Host("content[category2][key4] uncommented, now is {0}" -f $content["category2"]["key4"])
