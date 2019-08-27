Param(
$VMName,
$MemoryStartupBytes,
$NewVHDSizeBytes,
$IsoPath
)
$VM = New-VM $VMName $MemoryStartupBytes 2 -NewVHDPath ($VMName + ".vhdx") -NewVHDSizeBytes $NewVHDSizeBytes -BootDevice VHD -SwitchName External
Set-VM $VM -ProcessorCount 2 -MemoryMaximumBytes $MemoryStartupBytes -AutomaticCheckpointsEnabled $false
Set-VMFirmware $VM -EnableSecureBoot Off
Add-VMDvdDrive $VM -Path $IsoPath
Return $VM
