function Resolve-ModuleSource {
    $actualPath = Resolve-Path $PSScriptRoot

    # we expect $env:BH* to be empty when `Invoke-Build` is not used
    if ((Test-Path "$env:BHBuildOutput") -and ($actualPath -like "$(Resolve-Path $env:BHBuildOutput)/Tests/*")) {
        Join-Path -Path $env:BHBuildOutput -ChildPath "PSIni/PSIni.psd1"
    }
    else {
        Join-Path -Path $PSScriptRoot -ChildPath "../../PSIni/PSIni.psd1"
    }
}
