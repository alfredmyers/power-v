function Get-OrphanedVHDs {
	# Creates a list of files representing base VHDs concatenated with snapshots
	$rootedVHDs = (Get-VM).HardDrives.Path + (Get-VM | Get-VMSnapshot).HardDrives.Path

	# Checks each file in Hyper-V's default directory for VHDs against the previous list and returns those
	# not contained therein.
	Return Get-ChildItem (Get-VMHost).VirtualHardDiskPath | Where-Object { $_.FullName -notin $rootedVHDs }
}

function New-VirtualMachine {
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
	
		# If there's only one switch with external connectivity, it will be selected.
		# Else, a switch name should have been provided as an argument to the function
		# and the behavior is undefined
		if ($Switches.Count -eq 1) {
			$SwitchName = $Switches.Name
		}
	}

	# The VHD will be created at the host's default directory 
	$VHDPath = Join-Path -Path (Get-VMHost).VirtualHardDiskPath -ChildPath ($Name + ".vhdx")

	# Secure Boot is enabled/disabled depending on if a templated was passed as an argument to the function.
	if ($SecureBootTemplate -eq "MicrosoftWindows") {
		$null = New-VHD -Path $VHDPath -SizeBytes $VHDSizeBytes 
	}
	else {
		# Optimizes VHD settings for use with Linux.
		$null = New-VHD -Path $VHDPath -SizeBytes $VHDSizeBytes -BlockSizeBytes 1MB
	}

	# Defines the main settings for the VM.
	$VM = New-VM -Name $Name -MemoryStartupBytes $MemoryBytes -Generation 2 -BootDevice VHD -SwitchName $SwitchName -VHDPath $VHDPath
	Set-VM $VM -ProcessorCount 2 -MemoryMaximumBytes $MemoryBytes -AutomaticCheckpointsEnabled $false

	# Inserts the installation medium into the DVD drive.
	Add-VMDvdDrive $VM -Path $IsoPath

	# Removes the newtork card from the boot sequence. Otherwise, we would have to wait for PXE timing out
	Set-VMFirmware $VM -BootOrder ((Get-VMFirmware $VM).BootOrder | Where-Object BootType -eq 'Drive') 

	# If a Secure Boot template was provided, turns on Secure Boot and sets the template,
	# otherwise, turns Secure Boot off
	if ($SecureBootTemplate) {
		Set-VMFirmware $VM -SecureBootTemplate $SecureBootTemplate
	}
	else {
		Set-VMFirmware $VM -EnableSecureBoot Off -SecureBootTemplate 'MicrosoftUEFICertificateAuthority'
	}
	Return $VM
}

function Remove-VirtualMachine {
Param(
	$VMName
)

	$vm = Get-VM $VMName

	# If there are any snapshots, gets the root snapshot that would point to the base VHD.
	$snapshot = (Get-VMSnapshot $vm | Where-Object ParentSnapshotName -eq $null)

	# If snapshots were found in the previous step, gets the path to the base VHDs
	# Otherwise, gets the path to the VHDs from the VM itself.
	# *** And although the term is in plural, the code hasn't been tested with VMs attached
	# to more than a single virtual hard drive.
	if ($snapshot) {
		$vhds = $snapshot.HardDrives.Path
	}
	else {
		$vhds = $vm.HardDrives.Path
	}

	# The observed behavior of Remove-VM is it collapses existing snaphots before removing the VM.
	# There should be no surprises with a VM pointing to the last in a series of snapshots all 
	# pertaining to the same branch,
	# but the code hasn't been tested for when there are diverging branches of snapshots nor when
	# the VM is currently pointed to a snapshot that is parent to other snapshots.
	# How are the diverging branches collapsed - if at all?
	Remove-VM $vm -Force

	Remove-Item $vhds
}
