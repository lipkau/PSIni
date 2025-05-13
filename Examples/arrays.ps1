$content = Import-Ini .\settings.ini

$content["category2"]["key3"].GetType() # is an ArrayList
"--"
# before adding to the array
$content["category2"]["key3"].Add("new value") | Out-Null
# after adding to the array
$content["category2"]["key3"]
"--"

# before removing from the array
$content["category2"]["key3"].Remove("new value") | Out-Null
# after removing from the array
$content["category2"]["key3"]
"--"

# before replacing the array with a string value
$content["category2"]["key3"] = "new value"
# after replacing the array with a string value
$content["category2"]["key3"].GetType() # is a string
$content["category2"]["key3"]



