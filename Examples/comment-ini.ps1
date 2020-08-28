$content = Import-Ini .\settings.ini
$content["category2"]["Comment1"] = "a new string"
$content["category2"]["Comment2"] = "key4 = $($content["category2"]["key4"])"
$content["category2"]
