#!/bin/env bash
## Description:

## Author: Robin Björnsvik

# arch-chroot helper
_arch-chroot() {
    arch-chroot $mount /bin/bash -c "${1}"
}

# helper to change to $user inside arch-chroot
_user-chroot() {
	_arch-chroot "su - $1 -c '$2'"
}
