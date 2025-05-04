<#
.SYNOPSIS
Automates Disk Cleanup with storage space reporting.
.DESCRIPTION
Runs Windows Disk Cleanup with predefined settings and shows reclaimed space.
#>

param (
    [int]$SageRunNumber = 99  # Default cleanup profile
)

function Confirm-AdminPrivileges {
    <#
    .SYNOPSIS
    Ensures administrative privileges
    #>
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Elevating privileges..." -ForegroundColor Yellow
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -SageRunNumber $SageRunNumber"
        Start-Process powershell -ArgumentList $arguments -Verb RunAs
        Exit
    }
}

function Confirm-DiskCleanupNotRunning {
    <#
    .SYNOPSIS
    Prevents multiple cleanup instances
    #>
    if (Get-Process -Name cleanmgr -ErrorAction SilentlyContinue) {
        Write-Host @"
===============================================
 WARNING: Disk Cleanup is already running!
 Close existing instances before proceeding.
===============================================
"@ -ForegroundColor Red
        Exit
    }
}

function Get-DiskFreeSpace {
    <#
    .SYNOPSIS
    Gets C: drive free space in GB
    #>
    $disk = Get-WmiObject -Class Win32_LogicalDisk | 
            Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -eq "C:" } | 
            Select-Object FreeSpace

    if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 2) }
    else { 0 }
}

function Set-DiskCleanupOptions {
    <#
    .SYNOPSIS
    Configures registry cleanup settings
    #>
    param ([int]$SageRunNumber)

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    $stateFlag = "StateFlags$($SageRunNumber.ToString("0000"))"

    # Active cleanup options
    $options = @(
        "Active Setup Temp Folders",
        "Delivery Optimization Files",
        "Downloaded Program Files",
        "Internet Cache Files",
        "Temporary Files",
        "Thumbnail Cache",
        "Update Cleanup",
        "Windows Upgrade Log Files"
    )

    foreach ($option in $options) {
        $fullPath = Join-Path -Path $regPath -ChildPath $option
        if (Test-Path $fullPath) {
            Set-ItemProperty -Path $fullPath -Name $stateFlag -Value 2
            Write-Host " [✓] Enabled: $option" -ForegroundColor Green
        }
    }
}

function Start-DiskCleanup {
    <#
    .SYNOPSIS
    Executes cleanup with space reporting
    #>
    param ([int]$SageRunNumber)

    # Capture initial space
    $initialSpace = Get-DiskFreeSpace

    Write-Host "`nStarting Disk Cleanup..." -ForegroundColor Cyan
    cleanmgr.exe /sagerun:$SageRunNumber | Out-Null

    # Monitor process completion
    do {
        Start-Sleep -Seconds 3
    } while (Get-Process -Name cleanmgr -ErrorAction SilentlyContinue)

    # Calculate results
    $finalSpace = Get-DiskFreeSpace
    $spaceFreed = [math]::Round($finalSpace - $initialSpace, 2)

    # Display report
    Write-Host "`nCleanup Results:" -ForegroundColor Green
    Write-Host "-------------------------------"
    Write-Host " Initial Free Space: $initialSpace GB" -ForegroundColor Cyan
    Write-Host " Final Free Space:   $finalSpace GB" -ForegroundColor Cyan
    Write-Host " Space Reclaimed:    $([math]::Max($spaceFreed, 0)) GB" -ForegroundColor Yellow
}

# Main Execution
try {
    Confirm-AdminPrivileges
    Confirm-DiskCleanupNotRunning
    
    Write-Host "`nConfiguring Cleanup Options..." -ForegroundColor Cyan
    Set-DiskCleanupOptions -SageRunNumber $SageRunNumber
    
    Start-DiskCleanup -SageRunNumber $SageRunNumber
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Exit 1
}

Read-Host "`nPress Enter to exit..."