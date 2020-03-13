Describe "Pester" {
    It "a test" {
        $hash = [ordered]@{
            "Foo" = [ordered]@{
                "key1" = "value1"
                "key2" = @("lorem", "ipsum", "dolor")
            }
            "Bar" = [ordered]@{
                "key1" = "value3"
                "key2" = "value4"
            }
        }
        $hash = $hash
        $hash = $hash
        $hash = $hash

        , $hash["Foo"]["key2"] | Should -BeOfType [Array]
    }
}
