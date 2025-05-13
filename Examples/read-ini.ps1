$content = Import-Ini .\settings.ini

$content.Keys.Foreach({ "{0}: {1}" -f $_, ($content[$_] | Out-String) })
