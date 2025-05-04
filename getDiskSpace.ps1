function getDiskSpace
{$diskusage = Get-WmiObject -Class Win32_LogicalDisk | Where-Object{$_.DriveType -eq 3} | Select-Object DeviceID,FreeSpace,Size
foreach($disk in $diskUsage){
    $freespace = [math]::Round($disk.FreeSpace / 1GB,2)
    $totalspace = [math]::Round($disk.Size /1GB,2)
    $usedspace = $totalspace - $freespace

    Write-Host "Unidad: $($disk.DeviceID)"
    Write-Host "Espacio Libre $($freespace) GB"
    Write-Host "Espacio Utilizado $($usedspace) GB"
    Write-Host "Espacio Total $($totalspace) GB"

    Write-Host "----------------------------------"
}
Read-Host "Presione una tecla para salir..."
}
function getDiskUsedSpace
{
    $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object{ $_.DriveType -eq 3 -and $_.DeviceID -eq "C:" } | Select-Object DeviceID, FreeSpace, Size
    
    if ($disk) {
        $freespace = [math]::Round($disk.FreeSpace / 1GB,2)   
    }
    else{
        $freespace = 0
    }
    return $freespace
}
Write-Host "Unit C: as $(getDiskUsedSpace) GB of free space"