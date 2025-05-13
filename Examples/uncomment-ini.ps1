$content = Import-Ini .\settings.ini

# use regex to capture the key and value from the comment
if ($content["category1"]["Comment1"] -match "(.+)=(.*)") {
    # apply the captured groups to the 2 according variables
    $key, $value = $matches[1].Trim(), $matches[2].Trim()
    # add the key and value to the category1 section
    $content["category1"][$key] = $value
    # remove the comment from the category1 section
    $content["category1"].Remove("Comment1")
}

$content["category1"]
