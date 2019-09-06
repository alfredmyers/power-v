Param(
	$Name,
	$MemoryBytes,
	$VHDSizeBytes,
	$IsoPath,
	$SecureBootTemplate
)
$SwitchName = (Get-VMSwitch | Where-Object SwitchType -eq 'External').Name
$VHDPath = Join-Path -Path (Get-VMHost).VirtualHardDiskPath -ChildPath ($Name + ".vhdx")
if ($SecureBootTemplate -eq "MicrosoftWindows") {
	$null = New-VHD -Path $VHDPath -SizeBytes $VHDSizeBytes 
}
else {
	$null = New-VHD -Path $VHDPath -SizeBytes $VHDSizeBytes -BlockSizeBytes 1MB
}
$VM = New-VM -Name $Name -MemoryStartupBytes $MemoryBytes -Generation 2 -BootDevice VHD -SwitchName $SwitchName -VHDPath $VHDPath
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
