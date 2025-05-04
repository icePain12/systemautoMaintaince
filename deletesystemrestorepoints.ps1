# Require admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host

# Delete all restore points
try {
    Write-Host "Deleting ALL system restore points..." -ForegroundColor Yellow
    vssadmin delete shadows /all /quiet
    Write-Host "All system restore points have been deleted." -ForegroundColor Green
}
catch {
    Write-Host "Error occurred: $_" -ForegroundColor Red
}

# Optional: Verify no restore points remain
Write-Host "`nCurrent restore points:" -ForegroundColor Cyan
vssadmin list shadows

Pause
