################################################################################
#                               MODULE CODE                                  #
################################################################################

# Module Variables
$Script:TempPath = "$env:SystemRoot\Temp"
$Script:UserTempPath = $env:TEMP
$Script:WaitTime = 2000

# Admin Check Function
function Confirm-LDAdminPrivileges {
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "❌ Run PowerShell as Administrator!"
    }
}

# Temp Cleaning Function
function Clear-LDTempDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    try {
        Get-ChildItem -Path $Path -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction Stop
        Write-Host "✅ Cleaned: $Path" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error cleaning $Path: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main Initialization Function
function Initialize-Module {
    [CmdletBinding()]
    param(
        [switch]$CleanTempFolders
    )
    
    Confirm-LDAdminPrivileges
    
    if ($CleanTempFolders) {
        Write-Host "[+] Cleaning temporary directories..." -ForegroundColor Cyan
        Clear-LDTempDirectory -Path $Script:TempPath
        Clear-LDTempDirectory -Path $Script:UserTempPath
    }
}

# Export Functions and Variables (only necessary in a module file)
Export-ModuleMember -Function Initialize-Module, Clear-LDTempDirectory, Confirm-LDAdminPrivileges
Export-ModuleMember -Variable TempPath, UserTempPath, WaitTime

