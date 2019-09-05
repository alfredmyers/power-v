Param(
	$VMName
)
$vm = Get-VM $VMName
$snapshot = (Get-VMSnapshot $vm | ? ParentSnapshotName -eq $null)
if ($snapshot) {
	$vhds = $snapshot.HardDrives.Path
}
else {
	$vhds = $vm.HardDrives.Path
}
Remove-VM $vm -Force
Remove-Item $vhds
