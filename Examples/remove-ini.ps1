$content = Import-Ini .\settings.ini

Write-Output "Before removing key4"
$content["category2"].Keys

Write-Output "After removing key4"
$content["category2"].Remove("key4")
$content["category2"].Keys

