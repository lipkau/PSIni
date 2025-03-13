function Resolve-ModuleSource {
    $buildPath = Resolve-Path "$env:BHBuildOutput/*" -ErrorAction SilentlyContinue
    $actualPath = Resolve-Path $PSScriptRoot

    $resolvedPath = if ($actualPath -like $buildPath) {
        Join-Path -Path $env:BHBuildOutput -ChildPath "PSIni/PSIni.psd1"
    }
    else {
        Join-Path -Path $PSScriptRoot -ChildPath "../../PSIni/PSIni.psd1"
    }

    Resolve-Path $resolvedPath
}
