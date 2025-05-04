# Script to set audio output device using AudioDeviceCmdlets

# GLOBAL VARIABLES
$moduleName = "AudioDeviceCmdlets"
$moduleInstalled = Get-Module -ListAvailable -Name $moduleName

param(
    [int]$Signal = 0
)

# Check if the module is installed
if (-not $moduleInstalled) {
    Write-Host "Installing AudioDeviceCmdlets module..."
    try {
        # Install the module for the current user
        Install-Module -Name $moduleName -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "Module installed successfully."
    }
    catch {
        Write-Host "Failed to install module: $_" -ForegroundColor Red
        exit 1
    }
}

# Import the module
function ImportModule {
    try {
        Import-Module -Name $moduleName -ErrorAction Stop
        Write-Host "Module imported successfully."
    }
    catch {
        Write-Host "Failed to import module: $_" -ForegroundColor Red
        exit 1
    }
}

# Function to set the audio device
function SetAudioDevice {
    param(
        [int]$DeviceID
    )
    try {
        Write-Host "Attempting to set audio device to ID $DeviceID..."
        Set-AudioDevice -ID $DeviceID -ErrorAction Stop
        Write-Host "Audio device set to ID $DeviceID successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to set audio device: $_" -ForegroundColor Red
        Write-Host "Available devices:"
        Get-AudioDevice -List
        exit 1
    }
}

# Signal handling
switch ($Signal) {
    1 {
        SetAudioDevice -DeviceID 0
    }
    2 {
        SetAudioDevice -DeviceID 1
    }
}
