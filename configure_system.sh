#!/bin/env bash

## SYSTEM CONFIGURE
# Setup the new system with arch-root
# Generate fstab into the new system
source helpers.sh

# System config
USER=robin
USER_PASSWD=robin
HOSTNAME=archlinux
TIMEZONE=Europe/Stockholm
KEYMAP=sv-latin1
LANG=en_GB
ROOT_PASSWD=root
##Set Hostname
echo "Setting up hostname"
echo $HOSTNAME > /etc/hostname

# Timezone
echo "Setting locales and timezones"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Locales
echo KEYMAP=$KEYMAP > /etc/vconsole.conf
echo LANG=$LANG > /etc/locale.conf
echo LC_ALL=$LANG >> /etc/locale.conf
export LANG=$LANG
sed -i "s/#$LANG/$LANG/" /etc/locale.gen
locale-gen

# Set clock
echo "Setting the hardware clock"
hwclock --systohc --utc

# Set root password
echo "Setting root password"
echo root:$ROOT_PASSWD | chpasswd

# Add user
echo "Adding user $USER"
useradd -m -G wheel -s /bin/zsh $USER
echo $USER:$USER_PASSWD | chpasswd
sed -i '/^# %wheel ALL=(ALL) NOPASSWD: ALL/{s@^#@@}' /etc/sudoers
