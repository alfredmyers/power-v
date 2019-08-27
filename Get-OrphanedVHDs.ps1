Get-VM | Remove-VMSnapshot
$rootedVHDs = (Get-VM).HardDrives.Path
Return Get-ChildItem (Get-VMHost).VirtualHardDiskPath | Where-Object { $_.FullName -notin $rootedVHDs }
