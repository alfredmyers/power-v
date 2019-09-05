Param(
	$Name,
	$MemoryBytes,
	$VHDSizeBytes,
	$IsoPath,
	$SecureBootTemplate
)
$VM = New-VM -Name $Name -MemoryStartupBytes $MemoryBytes -Generation 2 -NewVHDPath ($Name + ".vhdx") -NewVHDSizeBytes $VHDSizeBytes -BootDevice VHD -SwitchName External
Set-VM $VM -ProcessorCount 2 -MemoryMaximumBytes $MemoryBytes -AutomaticCheckpointsEnabled $false
Add-VMDvdDrive $VM -Path $IsoPath
Set-VMFirmware $VM -BootOrder ((Get-VMFirmware $VM).BootOrder | ? BootType -eq 'Drive') 
if ($SecureBootTemplate) {
	Set-VMFirmware $VM -SecureBootTemplate $SecureBootTemplate
}
else {
	Set-VMFirmware $VM -EnableSecureBoot Off
}
Return $VM
