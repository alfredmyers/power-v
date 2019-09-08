Param(
	$Name,
	$MemoryBytes,
	$VHDSizeBytes,
	$IsoPath,
	$SecureBootTemplate,
	$SwitchName
)

# If a switch name hasn't been provided, it'll try to find a default.
if (!$SwitchName) {
	$Switches = Get-VMSwitch | Where-Object SwitchType -eq 'External'
	
	#If there's only one switch with external connectivity, that's it.
	#Else, a switch name should have been provided.
	if ($Switches.Count -eq 1) {
		$SwitchName = $Switches.Name
	}
}

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
