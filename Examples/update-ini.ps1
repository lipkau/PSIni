$content = Import-Ini .\settings.ini

# before changes
$content["category2"]

$content["category2"]["key4"] = "newvalue4"
$content["category2"]["newKey"] = "value for a new key"

# after changes
$content["category2"]
