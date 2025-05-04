# ================================
#             FUNCTIONS
# ================================
function Confirm-AdminPrivileges {
    <#
    .SYNOPSIS
    Ensures the script runs with administrative privileges
    #>
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Elevando a privilegios de administrador..." -ForegroundColor Yellow
        $scriptPath = $PSCommandPath
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process powershell -ArgumentList $arguments -Verb RunAs
        Exit
    }
}

function Invoke-SfcScan {
    <#
    .SYNOPSIS
    Runs SFC /scannow and returns the exit code
    #>
    try {
        Write-Host "`nEjecutando 'sfc /scannow'..." -ForegroundColor Yellow
        $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -PassThru -Wait -ErrorAction Stop
        return $sfcProcess.ExitCode
    }
    catch {
        Write-Host "Error en SFC: $($_.Exception.Message)" -ForegroundColor Red
        return -1
    }
}

function Invoke-DismRepair {
    <#
    .SYNOPSIS
    Runs DISM repair commands
    #>
    try {
        Write-Host "`nEjecutando comandos DISM..." -ForegroundColor Cyan
        
        $dismCommands = @(
            "/online /cleanup-image /scanhealth",
            "/online /cleanup-image /checkhealth",
            "/online /cleanup-image /restorehealth"
        )

        foreach ($cmd in $dismCommands) {
            Write-Host "Ejecutando: dism.exe $cmd" -ForegroundColor DarkCyan
            $dismProcess = Start-Process -FilePath "dism.exe" -ArgumentList $cmd -NoNewWindow -PassThru -Wait -ErrorAction Stop
            
            if ($dismProcess.ExitCode -ne 0) {
                Write-Host "DISM falló con código $($dismProcess.ExitCode) para: $cmd" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error en DISM: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ================================
#           MAIN SCRIPT
# ================================
Clear-Host
Confirm-AdminPrivileges
$maxAttempts = 3

# Initial SFC Scan
$sfcResult = Invoke-SfcScan

if ($sfcResult -eq 0) {
    Write-Host "`nNo se encontraron problemas. El programa finalizará." -ForegroundColor Green
    Pause
    Exit
}

# Repair Process Loop
for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    Write-Host "`nIntento de reparación $attempt de $maxAttempts" -ForegroundColor Magenta
    
    # Run DISM commands
    Invoke-DismRepair
    
    # Run SFC again
    $sfcResult = Invoke-SfcScan
    
    if ($sfcResult -eq 0) {
        Write-Host "`nLa computadora ha sido reparada exitosamente." -ForegroundColor Green
        Pause
        Exit
    }
}

# Final message if not repaired
Write-Host "`nSu PC tiene problemas complejos que no pueden repararse fácilmente." -ForegroundColor Red
Pause