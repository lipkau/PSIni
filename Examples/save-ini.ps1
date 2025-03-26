$category1 = @{"key1" = "value1"; "key2" = "value2" }
$category2 = @{"key3" = "value3"; "key4" = "value4" }
$content = @{"category1" = $category1; "category2" = $category2 }
Export-Ini -InputObject $content -Path .\settings2.ini
