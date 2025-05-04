### GLOBAL VARIABLES ###
$tempPath = "$env:SystemRoot\Temp"
$userTempPath = $env:TEMP
$waitTime = 2000

function Confirm-AdminPrivileges {
    <#
    .SYNOPSIS
    Ensures the script runs with administrative privileges
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

function Format-FileSize {
    param([decimal]$bytes)
    if ($bytes -eq 0) { return "0 Bytes" }
    
    $units = @('Bytes', 'KB', 'MB', 'GB', 'TB')
    $order = [math]::Floor([math]::Log($bytes, 1024))
    $size = $bytes / [math]::Pow(1024, $order)
    
    return "{0:N2} {1}" -f $size, $units[$order]
}

function Clear-TempFolder {
    param($path)
    $deletedSize = 0
    try {
        if (-not (Test-Path -Path $path)) {
            Write-Host "La carpeta $path no existe." -ForegroundColor Yellow
            return 0
        }

        # Calculate folder size before deletion
        $files = Get-ChildItem -Path $path -Recurse -Force -File -ErrorAction Stop
        $deletedSize = ($files | Measure-Object -Property Length -Sum).Sum

        # Delete contents
        Get-ChildItem -Path $path -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "Contenido de $path eliminado correctamente" -ForegroundColor Green
    }
    catch {
        Write-Host "Error al limpiar $path : $($_.Exception.Message)" -ForegroundColor Red
    }
    return $deletedSize
}

# Main execution
Confirm-AdminPrivileges
Clear-Host

Write-Host "System TEMP: $tempPath" -ForegroundColor Yellow
Write-Host "User TEMP: $userTempPath" -ForegroundColor Yellow

# Clean folders and get deleted sizes
Write-Host "`nEliminando contenido de la carpeta SYSTEM TEMP..." -ForegroundColor Cyan
Start-Sleep -Milliseconds $waitTime
$systemDeleted = Clear-TempFolder -path $tempPath

Write-Host "`nEliminando contenido de la carpeta USER TEMP..." -ForegroundColor Cyan
Start-Sleep -Milliseconds $waitTime
$userDeleted = Clear-TempFolder -path $userTempPath

# Show summary
Write-Host "`nResumen de limpieza:" -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green
Write-Host "Sistema TEMP eliminado: $(Format-FileSize $systemDeleted)" -ForegroundColor Yellow
Write-Host "Usuario TEMP eliminado: $(Format-FileSize $userDeleted)" -ForegroundColor Yellow
Write-Host "Total eliminado: $(Format-FileSize ($systemDeleted + $userDeleted))" -ForegroundColor Green -BackgroundColor DarkGray
Write-Host "`n"

Start-Sleep -Milliseconds 500
Pause