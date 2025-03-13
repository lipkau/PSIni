$content = Import-Ini .\settings.ini
$content["category2"]["key4"] = "newvalue4"
$content["category2"]["newKey"] = "value for a new key"
$content["category2"]
