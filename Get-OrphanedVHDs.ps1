$rootedVHDs = (Get-VM).HardDrives.Path + (Get-VM | Get-VMSnapshot).HardDrives.Path
Return Get-ChildItem (Get-VMHost).VirtualHardDiskPath | Where-Object { $_.FullName -notin $rootedVHDs }
