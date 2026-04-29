param([string]$Action = "open")
$ErrorActionPreference = "Stop"
$htmlPath = Join-Path $PSScriptRoot "cellular_automaton.html"

if ($Action -eq "open" -or $Action -eq "") {
    if (Test-Path $htmlPath) {
        Start-Process $htmlPath
        Write-Host "Opened cellular automaton in browser" -ForegroundColor Green
    } else {
        Write-Host "Error: cellular_automaton.html not found" -ForegroundColor Red
    }
} elseif ($Action -eq "path") {
    Write-Host $htmlPath
} else {
    Write-Host "Usage: .\cellular_automaton.ps1 [open|path]"
}
