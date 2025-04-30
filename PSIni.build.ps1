﻿[CmdletBinding()]
param(
    [ValidateSet('None', 'Normal' , 'Detailed', 'Diagnostic')]
    [String] $PesterVerbosity = 'Normal',

    [Parameter()]
    [String] $VersionToPublish
)

Import-Module "$PSScriptRoot/tools/BuildTools.psm1" -Force
Import-Module (Get-Dependency) -Force -ErrorAction Stop

Remove-Item -Path env:\BH* -ErrorAction SilentlyContinue
Set-BuildEnvironment -BuildOutput '$ProjectPath/release' -ErrorAction SilentlyContinue
$OS, $OSVersion = Get-HostInformation
# Add-ToModulePath -Path $env:BHBuildOutput

if ($VersionToPublish) {
    $VersionToPublish = $VersionToPublish.TrimStart('v') -as [Version]
}
$currentVersion = (Get-Metadata -Path $env:BHPSModuleManifest) -as [Version]
$builtManifestPath = "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1"

Task ShowDebugInfo {
    Write-Build Gray
    Write-Build Gray ('BHBuildSystem:              {0}' -f $env:BHBuildSystem)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray ('BHProjectName               {0}' -f $env:BHProjectName)
    Write-Build Gray ('BHProjectPath:              {0}' -f $env:BHProjectPath)
    Write-Build Gray ('BHModulePath:               {0}' -f $env:BHModulePath)
    Write-Build Gray ('BHPSModuleManifest:         {0}' -f $env:BHPSModuleManifest)
    Write-Build Gray ('BHBuildOutput:              {0}' -f $env:BHBuildOutput)
    Write-Build Gray ('builtManifestPath:          {0}' -f $builtManifestPath)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray ('BHBranchName:               {0}' -f $env:BHBranchName)
    Write-Build Gray ('BHCommitHash:               {0}' -f $env:BHCommitHash)
    Write-Build Gray ('BHCommitMessage:            {0}' -f $env:BHCommitMessage)
    Write-Build Gray ('BHBuildNumber               {0}' -f $env:BHBuildNumber)
    Write-Build Gray ('CurrentVersion              {0}' -f $currentVersion)
    Write-Build Gray ('VersionToPublish            {0}' -f $VersionToPublish)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString())
    Write-Build Gray ('OS:                         {0}' -f $OS)
    Write-Build Gray ('OS Version:                 {0}' -f $OSVersion)
    Write-Build Gray
}

Task Clean {
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "Test*.xml" -Force -ErrorAction SilentlyContinue
}

Task Build Clean, {
    if (-not (Test-Path "$env:BHBuildOutput/$env:BHProjectName")) {
        $null = New-Item -Path "$env:BHBuildOutput", "$env:BHBuildOutput/$env:BHProjectName" -ItemType Directory
    }
    # TODO:
    # replace data in manifest
}, CopyModuleFiles, CompileModule, UpdateManifest

# Synopsis: Generate ./release structure
Task CopyModuleFiles {
    Copy-Item -Path "$env:BHModulePath/*" -Destination "$env:BHBuildOutput/$env:BHProjectName" -Recurse -Force
    Copy-Item -Path @(
        "$env:BHProjectPath/CHANGELOG.md"
        "$env:BHProjectPath/LICENSE"
        "$env:BHProjectPath/README.md"
    ) -Destination "$env:BHBuildOutput/$env:BHProjectName" -Force

    $null = New-Item -Path "$env:BHBuildOutput/Tests" -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path "$env:BHProjectPath/Tests" -Destination $env:BHBuildOutput -Recurse -Force
    Copy-Item -Path "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1" -Destination $env:BHBuildOutput -Force
}

# Synopsis: Compile all functions into the .psm1 file
Task CompileModule {
    $regionsToKeep = @('Dependencies', 'Configuration')

    $targetFile = "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psm1"
    $content = Get-Content -Encoding UTF8 -LiteralPath $targetFile
    $capture = $false
    $compiled = ""

    foreach ($line in $content) {
        if ($line -match "^#region ($($regionsToKeep -join "|"))$") {
            $capture = $true
        }
        if (($capture -eq $true) -and ($line -match "^#endregion")) {
            $capture = $false
        }

        if ($capture) {
            $compiled += "$line`r`n"
        }
    }

    $PublicFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1" -ErrorAction SilentlyContinue )
    $PrivateFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Private/*.ps1" -ErrorAction SilentlyContinue )

    foreach ($function in @($PublicFunctions + $PrivateFunctions)) {
        $compiled += (Get-Content -Path $function.FullName -Raw)
        $compiled += "`r`n"
    }

    Set-Content -LiteralPath $targetFile -Value $compiled -Encoding UTF8 -Force
    Remove-Utf8Bom -Path $targetFile

    "Private", "Public" | ForEach-Object { Remove-Item -Path "$env:BHBuildOutput/$env:BHProjectName/$_" -Recurse -Force }
}

# Synopsis: Update the manifest of the module
Task UpdateManifest {
    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHPSModuleManifest -Force
    $moduleAlias = Get-Alias | Where-Object { $_.ModuleName -eq "$env:BHProjectName" }
    $moduleFunctions = (Get-ChildItem "$env:BHModulePath/Public/*.ps1").BaseName

    Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "FunctionsToExport" -Value @($moduleFunctions)
    Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "AliasesToExport" -Value ''
    if ($moduleAlias) {
        Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "AliasesToExport" -Value @($moduleAlias.Name)
    }
}

Task SetVersion {
    Assert-True { $VersionToPublish -as [Version] } "Invalid version format: $VersionToPublish"
    Assert-True { $VersionToPublish -gt $currentVersion } "Version must be greater than the current version: $currentVersion"

    Metadata\Update-Metadata -Path $builtManifestPath -PropertyName "ModuleVersion" -Value $VersionToPublish.ToString()
}

Task Test {
    $pesterConfig = [PesterConfiguration]::Default
    $pesterConfig.Output.Verbosity = $PesterVerbosity
    $pesterConfig.Run.path = @("$env:BHBuildOutput/Tests")
    $pesterConfig.Run.PassThru = $true
    $PesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.TestResult.OutputPath = "TestResults.xml"

    if ((Invoke-Pester -Configuration $pesterConfig).FailedCount -gt 0) {
        throw "Tests failed"
    }
}

Task Publish SetVersion, SignCode, Package, {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    Assert-True { Get-Module $env:BHProjectName -ListAvailable } "Module $env:BHProjectName is not available"

    Remove-Module $env:BHProjectName -ErrorAction Ignore

    Publish-Module -Name $env:BHProjectName -NuGetApiKey $PSGalleryAPIKey
}

Task SignCode {
    # TODO: waiting for certificates
}

Task Package {
    $source = "$env:BHBuildOutput\$env:BHProjectName"
    $destination = "$env:BHBuildOutput\$env:BHProjectName.zip"

    Assert-True { Test-Path $source } "Missing files to package"

    Remove-Item $destination -ErrorAction SilentlyContinue
    $null = Compress-Archive -Path $source -DestinationPath $destination
}

Task . Clean, Build, Test
