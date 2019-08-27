Param(
$VMName
)
$vm = Get-VM $VMName
Get-VMSnapshot $vm | Remove-VMSnapshot
$vhds = $vm.HardDrives.Path
Remove-VM $vm -Force
Remove-Item $vhds
