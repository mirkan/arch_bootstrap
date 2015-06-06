#!/bin/env bash
## Description:
## Automatic install of Arch Linux
# Requires partion and mountpoint already setup

## Author: Robin Björnsvik
set -ex
source helpers.sh

## GLOBALS
# Default mount
user=robin
mount=/mnt
dotfiles_rep="https://github.com/mirkan/dotfiles"
scripts_rep="https://github.com/mirkan/bash_scripts"

# Packages
mirrors="https://www.archlinux.org/mirrorlist/?country=SE&protocol=http&ip_version=4&use_mirror_status=on"

## SELECT MOUNT
# Select which mountpoint to use
_select_mount(){
	# Select mount where to run archbootstrap
	echo -n "Select mountpoint(Default /mnt): "
	read mountpoint

	# Default to $mount if empty
	[ $mountpoint ] && mount=$mountpoint

	#Check if mountpoint as valid
	mounted=$(mountpoint -q $mount && echo $?)
    if [ ! $mounted ];then
		echo "$mount doesn't seem to be mounted" 1>&2
        exit 1
	fi
}
## SET MIRRORS
# Generate mirrorlist for pacman before install
_set_mirrors(){
    # Download and select mirrors
    echo "Generating mirrorlist"
    tmpfile=$(mktemp --suffix=-mirrorlist)
    curl -so $tmpfile $mirrors
    sed -i 's/^#Server/Server/g' $tmpfile

    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
    mv $tmpfile /etc/pacman.d/mirrorlist

    # Rankmirrors to make this faster
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
    rankmirrors -n 3 /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
    rm /etc/pacman.d/mirrorlist.tmp
    chmod +r /etc/pacman.d/mirrorlist

    # Update pacman db
    pacman -Syy
}
## BASE INSTALL
# Run arch bootstrap and install base system
_base_install(){
    # Run pacstrap
    echo "Running pacstrap install"
    pacstrap $mount base base-devel

    # Generate fstab
    genfstab -p $mount >> $mount/etc/fstab

    # Copy the mirrorlist to the new system
    cp /etc/pacman.d/mirrorlist* $mount/etc/pacman.d
}

## SYSTEM CONFIGURE
# Setup the new system with arch-root
_system_configure(){
    echo "Configuring system"
    arch-chroot $mount /bin/bash -s < configure_system.sh
    ## Setup GRUB bootloader
    #echo "Setting up GRUB bootloader"
    #sudo grub-mkconfig -o /boot/grub/grub.cfg
}

## INSTALL PACKAGES
# Create new mirrorlist, modify pacman.conf and install packages
_install_packages(){
    # Uncomment multilib
    _arch-chroot "sed -i -r -e '/^#\[multilib\]/ { s/^#// ; n ; s/^#// }' /etc/pacman.conf"

    # Install packages
    echo "Installing packages...."
    _arch-chroot "pacman -Syy"
    _arch-chroot "pacman -S --noconfirm \
        $(sed '/^#/d' packages | tr '\n' ' ')"              # Avoid lines with comments and remove newlines
}

# INSTALL AUR PACKAGES
# Download and install AUR Packages with packer
_install_aur_packages() {
    # Install AUR packages
    echo "Installing packer"
    # Download packer, build and install
    _user-chroot $user "wget https://aur.archlinux.org/packages/pa/packer/PKGBUILD"
    _user-chroot $user "makepkg -is --noconfirm PKGBUILD"
    _user-chroot $user "rm -rf PKGBUILD pkg src packer*"

    # Install all AUR packages in 'packages_aur'
    echo "Installing AUR packages..."
    _user-chroot $user "packer -S  \
        $(sed '/^#/d' packages_aur | tr '\n' ' ') --noconfirm"
}

_dotfiles(){
    # Get git rep for dotfiles and scripts
    echo "Downloading dotfiles"
    _user-chroot $user "git clone $dotfiles_rep .dotfiles"
    _user-chroot $user "sh .dotfiles/install"
}

_bash_scripts(){
    # Downloads bash-scripts repo
    echo "Downloading bash-scripts"
    _user-chroot $user "git clone $scripts_rep .bin"
}
## RUNTIME
if [ "$(id -u)" != "0" ]; then
    echo "This script requires root." 1>&2
    exit 1
fi
_select_mount
#_set_mirrors
#_base_install
#_system_configure
#_install_packages
_install_aur_packages
_dotfiles
_bash_scripts
