#!/bin/env bash
# Set Hostname
echo "Setting up hostname"
echo $HOSTNAME > /etc/hostname

# Timezone
echo "Setting locales and timezones"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Locales
echo KEYMAP=$KEYMAP > /etc/vconsole.conf
echo LANG=$LOCALE > /etc/locale.conf
echo LC_ALL=$LOCALE >> /etc/locale.conf
export LANG=$LOCALE
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen

# Set clock
echo "Setting the hardware clock"
hwclock --systohc --utc

# Set root password
echo "Setting root password"
echo root:$PASSWORD | chpasswd

# Add user
echo "Adding user $USER"
useradd -m -G wheel -s $SHELL $USER
echo $USER:$PASSWORD | chpasswd

# Allow user sudo rights
sed -i '/^# %wheel ALL=(ALL) NOPASSWD: ALL/{s@^#@@}' /etc/sudoers
