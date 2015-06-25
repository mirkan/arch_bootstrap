# arch_bootstrap
My version of a simplified and automatic archlinux setup. Package installation and file-configuration has been a priority as I find it the most tedious and timeconsuming part of a new OS installation. So therefore I've left out the partitioning and the formatting part of the script. EFI is set as the bootloader.
###Pre-bootstrap
The following needs to be configured before running the script
* Partioning
* Format
* Mount

####Partitioning
In this example, I'm using 4 partitions: root, boot, swap and home. The home partition will be on a separate disk while the other three are on the same drive.
#####Erase everything first (if required):
`sgdisk -Z /dev/sda`

*/boot*:      
`sgdisk -n 1:0:+250M /dev/sda`

*/swap*:      
`sgdisk -n 2:0:+1G /dev/sda`

*/*:          
`sgdisk -n 3:0:0 /dev/sda`

*/home*:      
`sgdisk -n 1:0:+150G /dev/sdb`

*Change partition nr2 to type swap*:      
`sgdisk -t 2:8200 /dev/sda`

####Format
```
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sdb1
mkswap /dev/sda2
swapon /dev/sda2
```

####Mount
```
mount /dev/sda3 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 boot
mount /dev/sdb1 home
```

### Install
Simply fill up the `config` and the desired packages in `packages` and `packages_aur`. When everything is set, run the `install`.
