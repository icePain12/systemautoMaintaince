################################################################################
#                               MANTAINCE COMMANDS                             #
################################################################################

# ================================
#               IMPORTS
# ================================
# Import the module using FULL PATH
Import-Module "$PSScriptRoot\cleanuptempfiles.psm1" -Force

$Global:PreviousExecutionPolicy 

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
        Write-Host "Elevating to administrator privileges..." -ForegroundColor Yellow
        $scriptPath = $PSCommandPath
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -SageRunNumber $SageRunNumber"
        Start-Process powershell -ArgumentList $arguments -Verb RunAs
        Exit
    }
}

function createRestoringPoint {
    $currentTime = Get-Date -Format "ddMMyyyy_hhmmsstt"
    $description = "LDTech_maintenance_$currentTime"
    
    Enable-ComputerRestore -Drive "C:\"
    Checkpoint-Computer -Description $description -RestorePointType MODIFY_SETTINGS

    if (Get-ComputerRestorePoint | Where-Object { $_.Description -eq $description }) {
        Write-Host "✅ Restore point created" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Failed to create restore point" -ForegroundColor Red
    }
}
          ### Execution Policy Functions ###
function BackupAndSetExecutionPolicy {
    # Back up the current execution policy
    $Global:PreviousExecutionPolicy = Get-ExecutionPolicy
    Write-Host "Current execution policy backed up: $Global:PreviousExecutionPolicy"

    # Set the new execution policy
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    Write-Host "Execution policy set to 'Bypass' for the current process."
}

function RestoreExecutionPolicy {
    # Restore the previous execution policy
    if ($Global:PreviousExecutionPolicy) {
        Set-ExecutionPolicy -ExecutionPolicy $Global:PreviousExecutionPolicy -Force
        Write-Host "Execution policy restored to: $Global:PreviousExecutionPolicy"
    } else {
        Write-Host "No previous execution policy found. Unable to restore."
    }
}
# ================================
#               MAIN
# ================================
Clear-Host
Confirm-AdminPrivileges
# 1. Create restore point
createRestoringPoint
# 2. Set execution policy to bypass.
BackupAndSetExecutionPolicy
# 2. Clean temp files
& ".\cleanuptempfiles.ps1"
# clean disk files
&".\cleanupDisk.ps1"





# LAST: RESTORE EXECUTION POLICY
RestoreExecutionPolicy
Pause