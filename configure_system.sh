#!/bin/env bash

## SYSTEM CONFIGURE
# Setup the new system with arch-root
# Generate fstab into the new system

# System config
USER=robin
HOSTNAME=archlinux
TIMEZONE=Europe/Stockholm
LOCALE=en_GB.UTF-8
KEYMAP=sv-latin1
LANG=en_GB

##Set Hostname
echo "Setting up hostname"
echo $HOSTNAME > /etc/hostname

# Timezone
echo "Setting locales and timezones"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Locales
sed -i 's/#$LANG/$LANG/' /etc/locale.gen
echo KEYMAP=$KEYMAP > /etc/vconsole.conf
echo LANG=$LANG > /etc/locale.conf
echo LC_CTYPE=sv_SE.UTF-8 >> /etc/locale.conf
echo LC_COLLATE=C >> /etc/locale.conf
locale-gen

# Set root password
echo "Setting root password"
passwd

# Add user
echo "Adding user $USER"
useradd -m -G wheel -s /bin/zsh $USER
passwd $USER
sed -i '/^# %wheel ALL=(ALL) NOPASSWD: ALL/{s@^#@@}' /etc/sudoers
