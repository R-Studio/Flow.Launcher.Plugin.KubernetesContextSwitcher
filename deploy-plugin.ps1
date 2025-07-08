# Kubernetes Context Switcher Plugin Deployment Script
# PowerShell version

Write-Host "Deploying Kubernetes Context Switcher Plugin..." -ForegroundColor Green

# Build the project first
Write-Host "Building project..." -ForegroundColor Yellow
dotnet build -c Release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please fix the build errors first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Read version from plugin.json
$pluginJson = Get-Content "$PSScriptRoot\plugin.json" | ConvertFrom-Json
$version = $pluginJson.Version
Write-Host "Plugin version: $version" -ForegroundColor Cyan

# Define source and destination paths
$sourceDir = Get-Location
$pluginsDir = "$env:APPDATA\FlowLauncher\Plugins\KubernetesContextSwitcher-$version"
$buildDir = "$sourceDir\bin\Release\net7.0-windows7.0"

Write-Host "Source directory: $sourceDir" -ForegroundColor Cyan
Write-Host "Destination directory: $pluginsDir" -ForegroundColor Cyan

# Remove existing plugin directory if it exists
if (Test-Path $pluginsDir) {
    Write-Host "Removing existing plugin directory..." -ForegroundColor Yellow
    Remove-Item -Path $pluginsDir -Recurse -Force
}

# Create the plugin directory
Write-Host "Creating plugin directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null

# Copy all necessary files
Write-Host "Copying files..." -ForegroundColor Yellow

# Copy built DLL and dependencies
Copy-Item -Path "$buildDir\KubernetesContextSwitcher.dll" -Destination $pluginsDir -Force
Copy-Item -Path "$buildDir\KubernetesContextSwitcher.deps.json" -Destination $pluginsDir -Force

# Copy plugin.json
Copy-Item -Path "$sourceDir\plugin.json" -Destination $pluginsDir -Force

# Copy Images directory
Copy-Item -Path "$sourceDir\Images" -Destination $pluginsDir -Recurse -Force

# Copy README and LICENSE (optional but good practice)
Copy-Item -Path "$sourceDir\README.md" -Destination $pluginsDir -Force
Copy-Item -Path "$sourceDir\LICENSE" -Destination $pluginsDir -Force

Write-Host ""
Write-Host "Plugin deployed successfully!" -ForegroundColor Green
Write-Host "Plugin location: $pluginsDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart Flow Launcher" -ForegroundColor White
Write-Host "2. Use 'k8s' to activate the plugin" -ForegroundColor White
Write-Host "3. Check Flow Launcher settings -> Plugins to verify installation" -ForegroundColor White
Write-Host ""

# List the files that were copied
Write-Host "Files in plugin directory:" -ForegroundColor Cyan
Get-ChildItem -Path $pluginsDir -Recurse | ForEach-Object {
    Write-Host "  $($_.FullName.Replace($pluginsDir, ''))" -ForegroundColor White
}

Read-Host "Press Enter to exit" 