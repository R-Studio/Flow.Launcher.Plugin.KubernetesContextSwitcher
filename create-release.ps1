# Create Release Package for GitHub
# PowerShell script to prepare files for GitHub release

Write-Host "Creating release package for GitHub..." -ForegroundColor Green

# Read version from plugin.json
$pluginJson = Get-Content "$PSScriptRoot\plugin.json" | ConvertFrom-Json
$version = $pluginJson.Version
Write-Host "Plugin version: $version" -ForegroundColor Cyan

# Build the project
Write-Host "Building project..." -ForegroundColor Yellow
dotnet build -c Release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please fix the build errors first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create release directory
$releaseDir = "release-v$version"
if (Test-Path $releaseDir) {
    Remove-Item -Path $releaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null

Write-Host "Creating release package in: $releaseDir" -ForegroundColor Yellow

# Copy necessary files for release
$buildDir = "bin\Release\net7.0-windows7.0"

# Copy DLL and dependencies
Copy-Item -Path "$buildDir\KubernetesContextSwitcher.dll" -Destination $releaseDir -Force
Copy-Item -Path "$buildDir\KubernetesContextSwitcher.deps.json" -Destination $releaseDir -Force

# Copy plugin.json
Copy-Item -Path "plugin.json" -Destination $releaseDir -Force

# Copy Images directory
Copy-Item -Path "Images" -Destination $releaseDir -Recurse -Force

# Copy documentation
Copy-Item -Path "README.md" -Destination $releaseDir -Force
Copy-Item -Path "LICENSE" -Destination $releaseDir -Force

# Create a simple install script
$installScript = @"
# Installation Instructions
# 1. Extract this ZIP file
# 2. Copy the extracted folder to: `$env:APPDATA\FlowLauncher\Plugins\
# 3. Restart Flow Launcher
# 4. Use 'k8s' to activate the plugin

Write-Host "Plugin files extracted successfully!" -ForegroundColor Green
Write-Host "Please copy this folder to: `$env:APPDATA\FlowLauncher\Plugins\" -ForegroundColor Yellow
Write-Host "Then restart Flow Launcher." -ForegroundColor Yellow
"@

$installScript | Out-File -FilePath "$releaseDir\INSTALL.txt" -Encoding UTF8

# Create ZIP file
$zipFile = "KubernetesContextSwitcher-v$version.zip"
if (Test-Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}

Write-Host "Creating ZIP file: $zipFile" -ForegroundColor Yellow
Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipFile

# Clean up release directory
Remove-Item -Path $releaseDir -Recurse -Force

Write-Host ""
Write-Host "Release package created successfully!" -ForegroundColor Green
Write-Host "ZIP file: $zipFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to your GitHub repository" -ForegroundColor White
Write-Host "2. Click 'Releases' in the right sidebar" -ForegroundColor White
Write-Host "3. Click 'Create a new release'" -ForegroundColor White
Write-Host "4. Tag version: v$version" -ForegroundColor White
Write-Host "5. Title: Kubernetes Context Switcher v$version" -ForegroundColor White
Write-Host "6. Upload the ZIP file: $zipFile" -ForegroundColor White
Write-Host "7. Publish the release" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit" 