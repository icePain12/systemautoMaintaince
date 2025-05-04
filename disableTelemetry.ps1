function Confirm-AdminPrivileges {
    <#
    .SYNOPSIS
    Ensures the script runs with administrative privileges.
    #>
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Elevating to administrator privileges..." -ForegroundColor Yellow
        $scriptPath = $PSCommandPath
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process powershell -ArgumentList $arguments -Verb RunAs
        Exit
    }
}
Confirm-AdminPrivileges
Clear-Host

# --- Registry modifications to disable telemetry ---
# Variables for registry key
$location = "HKLM:\Software\Policies\Microsoft\Windows\DataCollection"
$name = "AllowTelemetry"
$value = "0"

# Ensure the registry path exists (create if not)
if (-not (Test-Path $location)) {
    New-Item -Path $location -Force | Out-Null
}

try {
    # Add or update the registry entry for AllowTelemetry
    New-ItemProperty -Path $location -Name $name -Value $value -PropertyType String -Force | Out-Null
    Write-Host "$name registry key added to $location with value $value successfully." -ForegroundColor Green
}
catch {
    Write-Host "There were issues creating your $name registry key." -ForegroundColor Red
}

# --- Telemetry service disabling ---
# The telemetry service (DiagTrack) is responsible for sending Windows telemetry data.
if (Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue) {
    try {
        # Stop the DiagTrack service if it is running
        Stop-Service -Name "DiagTrack" -Force -ErrorAction Stop
        # Disable the service so that it does not start automatically
        Set-Service -Name "DiagTrack" -StartupType Disabled
        Write-Host "DiagTrack service has been stopped and disabled successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to disable the DiagTrack service. Please check your system settings or try again." -ForegroundColor Red
    }
}
else {
    Write-Host "DiagTrack service not found on this system." -ForegroundColor Yellow
}

# --- Optionally, you can add firewall rules to block telemetry endpoints ---
<# 
Example: 
New-NetFirewallRule -DisplayName "Block Telemetry" -Direction Outbound -RemoteAddress <TELEMETRY_IP_OR_DOMAIN> -Action Block
#>
