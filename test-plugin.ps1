# Test script for Kubernetes Context Switcher Plugin
# This script helps verify that kubectl is working correctly

Write-Host "Testing Kubernetes Context Switcher Plugin..." -ForegroundColor Green
Write-Host ""

# Test 1: Check if kubectl is available
Write-Host "Test 1: Checking kubectl availability..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client --output=json 2>$null | ConvertFrom-Json
    Write-Host "✓ kubectl found: $($kubectlVersion.clientVersion.gitVersion)" -ForegroundColor Green
} catch {
    Write-Host "✗ kubectl not found or not working" -ForegroundColor Red
    Write-Host "Please install kubectl and ensure it's in your PATH" -ForegroundColor Yellow
    exit 1
}

# Test 2: Check current context
Write-Host ""
Write-Host "Test 2: Getting current context..." -ForegroundColor Yellow
try {
    $currentContext = kubectl config current-context 2>$null
    if ($currentContext) {
        Write-Host "✓ Current context: $currentContext" -ForegroundColor Green
    } else {
        Write-Host "✗ No current context found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Failed to get current context" -ForegroundColor Red
}

# Test 3: List all contexts
Write-Host ""
Write-Host "Test 3: Listing all contexts..." -ForegroundColor Yellow
try {
    $contexts = kubectl config get-contexts -o name 2>$null
    if ($contexts) {
        Write-Host "✓ Found $($contexts.Count) contexts:" -ForegroundColor Green
        foreach ($context in $contexts) {
            $marker = if ($context -eq $currentContext) { " (current)" } else { "" }
            Write-Host "  - $context$marker" -ForegroundColor White
        }
    } else {
        Write-Host "✗ No contexts found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Failed to list contexts" -ForegroundColor Red
}

# Test 4: Check kubeconfig location
Write-Host ""
Write-Host "Test 4: Checking kubeconfig..." -ForegroundColor Yellow
$kubeconfig = $env:KUBECONFIG
if ($kubeconfig) {
    Write-Host "✓ KUBECONFIG environment variable: $kubeconfig" -ForegroundColor Green
} else {
    $defaultKubeconfig = "$env:USERPROFILE\.kube\config"
    if (Test-Path $defaultKubeconfig) {
        Write-Host "✓ Using default kubeconfig: $defaultKubeconfig" -ForegroundColor Green
    } else {
        Write-Host "✗ No kubeconfig found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Plugin test completed!" -ForegroundColor Green
Write-Host "If all tests passed, the plugin should work correctly." -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit" 