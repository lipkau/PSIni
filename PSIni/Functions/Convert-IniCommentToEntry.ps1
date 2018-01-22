Function Convert-IniCommentToEntry {
    <#
    .SYNOPSIS
        Internal module function to remove the old comment then insert a new key/value pair at the old location with the previous comment's value.
    #>
    param ($content, $key, $section, $commentChar)

    $index = 0
    $commentFound = $false

    $commentRegex = "^([$($commentChar -join '')]$key.*)$"
    Write-Debug ("commentRegex is {0}." -f $commentRegex)

    foreach ($entry in $content[$section].GetEnumerator()) {
        Write-Debug ("Uncomment looking at key '{0}' with value '{1}'." -f $entry.key, $entry.value)

        if ($entry.key.StartsWith('Comment') -and $entry.value -match $commentRegex) {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Uncommenting '{0}' in {1} section." -f $entry.value, $section)
            $oldKey = $entry.key
            $split = $entry.value.Split("=")

            if ($split.Length -ge 2) {
                $newValue = $split[1].Trim()
            }
            else {
                # If the split did not result in 2+ items, it was not in the key=value form.
                # So just uncomment the key, as there is no value. It will result in a "key=" formatted output.
                $newValue = ''
            }

            # Break out once a match is found. If there are multiple commented out keys
            # with the same name, we can't add them anyway since it's a hash.
            $commentFound = $true
            break
        }
        $index++
    }

    if ($commentFound) {
        if ($content[$section][$key]) {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Unable to uncomment '{0}' key in {1} section as there is already a key with that name." -f $key, $section)
        }
        else {
            Write-Debug ("Removing '{0}'." -f $oldKey)
            $content[$section].Remove($oldKey)
            Write-Debug ("Inserting [{0}][{1}] = {2} at index {3}." -f $section, $key, $newValue, $index)
            $content[$section].Insert($index, $key, $newValue)
        }
    }
    else {
        Write-Verbose ("$($MyInvocation.MyCommand.Name):: Did not find '{0}' key in {1} section to uncomment." -f $key, $section)
    }
}
