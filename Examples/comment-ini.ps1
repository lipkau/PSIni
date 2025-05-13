$content = Import-Ini .\settings.ini

# add a new comment
$content["category2"]["__Comment1"] = "a new string"

# replace a key with a comment
$content["category2"]["__Comment2"] = "key4 = $($content["category2"]["key4"])"
$content["category2"].Remove("key4")

$content["category2"]
