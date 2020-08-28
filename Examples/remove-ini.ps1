$content = Import-Ini .\settings.ini
$content["category2"].Remove("key4")
if (!$content["category2"]["key4"]) { Write-Host "content[category2][key4] no longer exists." }
