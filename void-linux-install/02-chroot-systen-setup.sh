#!/bin/bash
# Void Linux Full Disk Encryption Installation Script
# ================================================================
# This script performs a secure full disk encryption setup on a specified
# drive using LUKS (LUKS1) and Btrfs subvolumes. The script also
# configures GRUB with cryptodisk support, generates a keyfile for
# automatic unlocking, and installs a collection of useful packages.
#
# Usage: sudo ./install-void-fde.sh
#
# WARNING: This will erase all data on the target drive!
# ================================================================

set -euo pipefail
IFS=$'\n\t'
source 00-variables-functions.sh


#----------------------------------------
# Preliminary Checks
#----------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

#----------------------------------------
# Install Base System and Necessary Tools
#----------------------------------------
# Root password
log "Setting root password"
passwd

# Enable wheel group in sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Add normal user
log "Setting user password"
useradd -m denis
usermod -aG wheel,audio,video,storage,network,input,kvm denis
passwd denis

#----------------------------------------
# Change default shell
#----------------------------------------
log "Setting system default shell"
chsh -s /bin/bash root

#----------------------------------------
# Hostname and locale settings
#----------------------------------------
# Hostname configuration
log "Setting hostname to: $HOSTNAME"
echo "${HOSTNAME}" > /etc/hostname

echo "127.0.0.1   localhost"                             >  /etc/hosts
echo "::1         localhost"                             >> /etc/hosts
echo "127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}"   >> /etc/hosts

# Locale settings
log "Setting locale to: $LOCALE"
echo "${LOCALE} UTF-8" > /etc/default/libc-locales
echo "LANG=${LOCALE}" > /etc/locale.conf

#----------------------------------------
# Luks drive related configs
#----------------------------------------
# LUKS keyfile generation and permissions
log "Creating key key file"
dd bs=1 count=64 if=/dev/urandom of=${KEYFILE}
chmod 000 ${KEYFILE}
chmod -R g-rwx,o-rwx /boot

# Add LUKS keyfile to container
log "Adding keyfile to drive"
cryptsetup luksAddKey "${DRIVE}${PART_SUFFIX}2" ${KEYFILE}

# Crypttab configuration
log "Setting the Crypttab with keyfile"
UEFI_UUID=$(blkid -s UUID -o value ${DRIVE}${PART_SUFFIX}1)
LUKS_UUID=$(blkid -s UUID -o value ${DRIVE}${PART_SUFFIX}2)
ROOT_UUID=$(blkid -s UUID -o value ${MAPPER_PATH})
echo "${CRYPT_NAME} UUID=${LUKS_UUID} ${KEYFILE} luks" > /etc/crypttab

#----------------------------------------
# Fstab generation
#----------------------------------------
# EFI_UUID=$(blkid -s UUID -o value ${DRIVE}${PART_SUFFIX}1)

# echo "/dev/mapper/${CRYPT_NAME}  /		 btrfs ${BTRFS_OPTS},subvol=@		         0 1" >  /etc/fstab
# echo "/dev/mapper/${CRYPT_NAME}  /home	         btrfs ${BTRFS_OPTS},subvol=@home		 0 2" >> /etc/fstab
# echo "/dev/mapper/${CRYPT_NAME}  /.snapshots	 btrfs ${BTRFS_OPTS},subvol=@snapshots	         0 2" >> /etc/fstab
# echo "/dev/mapper/${CRYPT_NAME}  /var/cache	 btrfs ${BTRFS_OPTS},subvol=@var_cache	         0 2" >> /etc/fstab
# echo "/dev/mapper/${CRYPT_NAME}  /var/cache/xbps btrfs ${BTRFS_OPTS},subvol=@var_cache_xbps	 0 2" >> /etc/fstab
# echo "/dev/mapper/${CRYPT_NAME}  /var/tmp	 btrfs ${BTRFS_OPTS},subvol=@var_tmp	         0 2" >> /etc/fstab
# echo "/dev/mapper/${CRYPT_NAME}  /var/srv	 btrfs ${BTRFS_OPTS},subvol=@var_srv	         0 2" >> /etc/fstab
# echo "UUID=${EFI_UUID}           /boot/efi       vfat  defaults	                                 0 2" >> /etc/fstab

#----------------------------------------
# GRUB installation
#----------------------------------------
# GRUB cryptodisk and kernel parameters
log "Preparing GRUB instalation with encrypted disk"
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=4 rd.auto=1 rd.luks.allow-discards rd.luks.uuid=${LUKS_UUID}\"|" /etc/default/grub

# Include keyfile and crypttab in initramfs
echo "install_items+=\" ${KEYFILE} /etc/crypttab \"" > /etc/dracut.conf.d/10-crypt.conf
ln -s /etc/sv/dhc /etc/runit/runsvdir/default

# Install GRUB and generate config
log "Installing GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --bootloader-id=Void
grub-mkconfig -o /boot/grub/grub.cfg

#----------------------------------------
# Final packages and services 
#----------------------------------------
# Reconfigure all settings
log "Locale reconfiguration"
xbps-reconfigure -fa

# Add nonfree repo
xbps-install -Sy void-repo-nonfree
xbps-install -S

# Sound packages
xbps-install -y alsa-utils alsa-plugins-pulseaudio apulse pipewire alsa-pipewire libjack-pipewire pulseaudio pavucontrol
mkdir -p /etc/pipewire/pipewire.conf.d
ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

mkdir -p /etc/alsa/conf.d
ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d
ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d

# Window Managers
echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc | sudo tee /etc/xbps.d/hyprland-void.conf
xbps-install -Sy hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpaper hypridle hyprlock Waybar wlogout

# Install other useful packages
log "Installing additional packages"
xbps-install -Su
xbps-install -y "${ADDITIONAL_PKGS[@]}"

# Enable essential services
log "Linking essential services"
# ln -sf /etc/sv/dbus		/var/service
# ln -sf /etc/sv/udevd		/var/service
# ln -sf /etc/sv/sshd		/var/service
# ln -sf /etc/sv/sddm		/var/service
# ln -sf /etc/sv/wpa_supplicant	/var/service
# ln -sf /etc/sv/dhcpcd		/var/service
# ln -sf /etc/sv/elogind	/var/service
# ln -sf /etc/sv/alsa           /var/service


log "Installation complete. Please reboot into your new Void Linux system."

