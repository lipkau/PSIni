$content = Import-Ini .\settings.ini
if ($content["category1"]["Comment1"] -match "(.+)=(.*)") {
    $key, $value = $matches[1].Trim(), $matches[2].Trim()
    $content["category1"][$key] = $value
    $content["category1"].Remove("Comment1")
}
$content["category1"]
