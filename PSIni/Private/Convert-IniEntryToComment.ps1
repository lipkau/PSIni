Function Convert-IniEntryToComment {
    <#
    .SYNOPSIS
        Internal module function to remove the old key then insert a new one at the old location in the comment style used by Get-IniContent.
    #>
    param ($content, $key, $section, $commentChar)

    # Comments in Get-IniContent start with 1, not zero.
    $commentCount = 1

    foreach ($entry in $content[$section].GetEnumerator()) {
        if ($entry.key.StartsWith('Comment')) {
            $commentCount++
        }
    }

    Write-Debug ("commentCount is {0}." -f $commentCount)

    $desiredValue = $content[$section][$key]

    # Don't attempt to comment out non-existent keys.
    if ($desiredValue) {
        Write-Debug ("desiredValue is {0}." -f $desiredValue)

        $commentKey = 'Comment' + $commentCount
        Write-Debug ("commentKey is {0}." -f $commentKey)

        $commentValue = $commentChar[0] + $key + '=' + $desiredValue
        Write-Debug ("commentValue is {0}." -f $commentValue)

        # Thanks to http://stackoverflow.com/a/35731603/844937. However, that solution is case sensitive.
        # Tried $index = $($content[$section].keys).IndexOf($key, [StringComparison]"CurrentCultureIgnoreCase")
        # but it said there were no IndexOf overloads with two arguments. So if we get a -1 (not found),
        # use a variation on http://stackoverflow.com/a/34930231/844937 to search for a case-insensitive match.
        $sectionKeys = $($content[$section].keys)
        $index = $sectionKeys.IndexOf($key)
        Write-Debug ("Index of {0} is {1}." -f $key, $index)

        if ($index -eq -1) {
            $i = 0
            foreach ($sectionKey in $sectionKeys) {
                if ($sectionKey -match $key) {
                    $index = $i
                    Write-Debug ("Index updated to {0}." -f $index)
                    break
                }
                else {
                    $i++
                }
            }
        }

        if ($index -ge 0) {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Commenting out {0} key in {1} section." -f $key, $section)
            $content[$section].Remove($key)
            $content[$section].Insert($index, $commentKey, $commentValue)
        }
        else {
            Write-Verbose ("$($MyInvocation.MyCommand.Name):: Could not find '{0}' key in {1} section to comment out." -f $key, $section)
        }
    }
}
