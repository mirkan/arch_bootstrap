#!/bin/env bash
## Description:
## Automatic install of Arch Linux
# Requires partion and mountpoint already setup

## Author: Robin Björnsvik
set -ex

## GLOBALS
# Default mount
user=robin
MOUNT=/mnt
REP="https://github.com/mirkan/dotfiles"
# Packages
MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=SE&protocol=http&ip_version=4&use_mirror_status=on"

#arch-chroot helper
_arch-chroot() {
  arch-chroot $MOUNT /bin/bash -c "${1}"
}

## SELECT MOUNT
# Select which mountpoint to use
_select_mount(){
	# Select mount where to run archbootstrap
	echo -n "Select mountpoint(Default /mnt): "
	read mountpoint

	# Default to $MOUNT if empty
	[ $mountpoint ] && MOUNT=$mountpoint

	#Check if mountpoint as valid
	mounted=$(mountpoint -q $MOUNT && echo $?)
    if [ ! $mounted ];then
		echo "$MOUNT doesn't seem to be mounted" 1>&2
        exit 1
	fi
}
## SET MIRRORS
# Generate mirrorlist for pacman before install
_set_mirrors(){
    # Download and select mirrors
    echo "Generating mirrorlist"
    tmpfile=$(mktemp --suffix=-mirrorlist)
    curl -so ${tmpfile} ${MIRRORLIST}
    sed -i 's/^#Server/Server/g' ${tmpfile}

    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
    mv ${tmpfile} /etc/pacman.d/mirrorlist

    # Rankmirrors to make this faster (though it takes a while)
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
    pacstrap $MOUNT base base-devel

    # Generate fstab
    genfstab -p $MOUNT >> $MOUNT/etc/fstab

    # Copy the mirrorlist to the new system
    cp /etc/pacman.d/mirrorlist* $MOUNT/etc/pacman.d
}

## SYSTEM CONFIGURE
# Setup the new system with arch-root
_system_configure(){
    arch-chroot $MOUNT /bin/bash -s < configure_system.sh
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
        $(sed '/^#/d' packages | tr '\n' ' ')"
}

# INSTALL AUR PACKAGES
# Download and install AUR Packages with packer
_install_aur_packages() {
    # Install AUR packages
    echo "Installing packer"

    # Download packer and install
    _arch-chroot "wget --output-document=home/$user/PKGBUILD https://aur.archlinux.org/packages/pa/packer/PKGBUILD"
    _arch-chroot "su - $user -c 'makepkg -is --noconfirm PKGBUILD'"
    _arch-chroot "rm -r home/$user/{PKGBUILD,packer}"

    # Install all AUR packages in 'packages_aur'
    echo "Installing AUR packages..."
    _arch-chroot "su - $user -c 'packer -S  \
        $(sed '/^#/d' packages_aur | tr '\n' ' ') --noconfirm'"
}

_dotfiles(){

    # Get git rep
    _arch-chroot "su - $user -c 'git clone $REP .dotfiles'"
    _arch-chroot "su - $user -c 'sh .dotfiles/install'"
}
## RUNTIME
if [ "$(id -u)" != "0" ]; then
    echo "This script requires root." 1>&2
    exit 1
fi
_select_mount
_set_mirrors
#_base_install
_system_configure
_install_packages
_install_aur_packages
_dotfiles
