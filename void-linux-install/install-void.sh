#!/bin/bash
# Void Linux Full Disk Encryption Installation Script
# ================================================================
# This script performs a secure full disk encryption setup on a specified
# drive using LUKS (LUKS1) and Btrfs subvolumes. The script also
# configures GRUB with cryptodisk support, generates a keyfile for
# automatic unlocking, and installs a collection of useful packages.
#
# Usage: sudo ./install-void.sh
#
# WARNING: This will erase all data on the target drive!
# ================================================================

set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IFS=$'\n\t'

log() {
    printf "[%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

confirm() {
    read -rp "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) true ;;  *) false ;;
    esac
}

DRIVE="/dev/sda"
HOSTNAME="void"
CRYPT_NAME="crypt"
MAPPER_PATH="/dev/mapper/$CRYPT_NAME"
MOUNTPOINT="/mnt"
LOCALE="en_US.UTF-8"
KEYFILE="/boot/volume.key"
REPO_URL="https://repo-de.voidlinux.org/current"
BTRFS_OPTS="noatime,compress=zstd,discard=async"
ADDITIONAL_PKGS=("bat" "btop" "vsv" "xz" "fzf" "ripgrep" "ghostty" "kitty" "vim" "neovim" "font-awesome6" "tealdeer" "eza" "sddm" "elogind" "nvidia" "Thunar" "wofi" "grimshot")

if [[ "$DRIVE" =~ "nvme" ]]; then
    PART_SUFFIX="p"
else
    PART_SUFFIX=""
fi
log "Using partition suffix '$PART_SUFFIX' for drive $DRIVE."

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

if [[ "${INSIDE_CHROOT:-}" != "1" ]]; then
    log "Target drive is ${DRIVE}. All data on this drive will be erased!"
    if ! confirm "Are you sure you want to continue?"; then
        log "User aborted. Exiting."
        exit 1
    fi

    log "Partitioning ${DRIVE}..."
    sfdisk --wipe always --label gpt "${DRIVE}" << EOF
1M,512M,U
,+,L
EOF
    log "Partitioning complete: ${DRIVE}${PART_SUFFIX}1 (EFI), ${DRIVE}${PART_SUFFIX}2 (LUKS)."

    log "Formatting EFI partition..."
    mkfs.vfat -F32 "${DRIVE}${PART_SUFFIX}1"
    log "EFI partition formatted as FAT32."

    log "Setting up LUKS encryption on ${DRIVE}${PART_SUFFIX}2..."
    cryptsetup luksFormat --type luks1 "${DRIVE}${PART_SUFFIX}2"
    cryptsetup open     "${DRIVE}${PART_SUFFIX}2" "${CRYPT_NAME}"
    log "LUKS container opened at ${MAPPER_PATH}."

    log "Creating Btrfs filesystem and subvolumes..."
    mkfs.btrfs             "${MAPPER_PATH}"
    mount                  "${MAPPER_PATH}" "${MOUNTPOINT}"
    btrfs subvolume create "${MOUNTPOINT}/@"
    btrfs subvolume create "${MOUNTPOINT}/@home"
    btrfs subvolume create "${MOUNTPOINT}/@snapshots"
    btrfs subvolume create "${MOUNTPOINT}/@var_cache_xbps"
    btrfs subvolume create "${MOUNTPOINT}/@var_tmp"
    btrfs subvolume create "${MOUNTPOINT}/@srv"
    umount                 "${MOUNTPOINT}"
    log "Btrfs subvolumes created successfully."

    log "Mounting subvolumes and EFI partition..."
    mount -o ${BTRFS_OPTS},subvol=@               "${MAPPER_PATH}" "${MOUNTPOINT}"

    mkdir -p "${MOUNTPOINT}"/{boot/efi,home,.snapshots,var/cache/xbps,var/tmp,srv}

    mount -o ${BTRFS_OPTS},subvol=@home           "${MAPPER_PATH}" "${MOUNTPOINT}/home"
    mount -o ${BTRFS_OPTS},subvol=@snapshots      "${MAPPER_PATH}" "${MOUNTPOINT}/.snapshots"
    mount -o ${BTRFS_OPTS},subvol=@var_cache_xbps "${MAPPER_PATH}" "${MOUNTPOINT}/var/cache/xbps"
    mount -o ${BTRFS_OPTS},subvol=@var_tmp        "${MAPPER_PATH}" "${MOUNTPOINT}/var/tmp"
    mount -o ${BTRFS_OPTS},subvol=@srv            "${MAPPER_PATH}" "${MOUNTPOINT}/srv"
    mount "${DRIVE}${PART_SUFFIX}1" "${MOUNTPOINT}/boot/efi"
    log "All partitions and subvolumes mounted."

    log "Installing base system and essential packages..."

    mkdir -p /mnt/var/db/xbps/keys
    cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

    xbps-install -Sy -R "${REPO_URL}" -r "${MOUNTPOINT}" \
        base-system xtools grub-x86_64-efi cryptsetup btrfs-progs

    cp /etc/resolv.conf "${MOUNTPOINT}/etc/resolv.conf"
    log "Base system installed"

    log "Generating fstab"
    xgenfstab -U "${MOUNTPOINT}" > "${MOUNTPOINT}/etc/fstab"

    cp "${SCRIPT_DIR}/install-void.sh" "${MOUNTPOINT}/tmp/"

    log "Running chroot setup..."
    xchroot "${MOUNTPOINT}" /bin/bash -c 'export INSIDE_CHROOT=1; /tmp/install-void.sh'

    log "Installation complete. Please reboot into your new Void Linux system."
    exit 0
else
    log "Setting root password"
    passwd

    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    log "Setting user password"
    useradd -m denis
    usermod -aG wheel,audio,video,storage,network,input,kvm denis
    passwd denis

    log "Setting system default shell"
    chsh -s /bin/bash root

    log "Setting hostname to: $HOSTNAME"
    echo "${HOSTNAME}" > /etc/hostname

    echo "127.0.0.1   localhost"                             >  /etc/hosts
    echo "::1         localhost"                             >> /etc/hosts
    echo "127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}"   >> /etc/hosts

    log "Setting locale to: $LOCALE"
    echo "${LOCALE} UTF-8" > /etc/default/libc-locales
    echo "LANG=${LOCALE}" > /etc/locale.conf

    log "Creating key key file"
    dd bs=1 count=64 if=/dev/urandom of=${KEYFILE}
    chmod 000 ${KEYFILE}
    chmod -R g-rwx,o-rwx /boot

    log "Adding keyfile to drive"
    cryptsetup luksAddKey "${DRIVE}${PART_SUFFIX}2" ${KEYFILE}

    log "Setting the Crypttab with keyfile"
    UEFI_UUID=$(blkid -s UUID -o value ${DRIVE}${PART_SUFFIX}1)
    LUKS_UUID=$(blkid -s UUID -o value ${DRIVE}${PART_SUFFIX}2)
    ROOT_UUID=$(blkid -s UUID -o value ${MAPPER_PATH})
    echo "${CRYPT_NAME} UUID=${LUKS_UUID} ${KEYFILE} luks" > /etc/crypttab

    log "Preparing GRUB instalation with encrypted disk"
    echo 'GRUB_ENABLE_CRYPTODISK=y' >> /etc/default/grub
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=4 rd.auto=1 rd.luks.allow-discards rd.luks.uuid=${LUKS_UUID}\"|" /etc/default/grub

    echo "install_items+=\" ${KEYFILE} /etc/crypttab \"" > /etc/dracut.conf.d/10-crypt.conf
    ln -s /etc/sv/dhc /etc/runit/runsvdir/default/

    log "Installing GRUB"
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --bootloader-id=Void
    grub-mkconfig -o /boot/grub/grub.cfg

    log "Locale reconfiguration"
    xbps-reconfigure -fa

    xbps-install -Sy void-repo-nonfree
    xbps-install -S

    xbps-install -y alsa-utils alsa-plugins-pulseaudio apulse pipewire alsa-pipewire libjack-pipewire pulseaudio pavucontrol
    mkdir -p /etc/pipewire/pipewire.conf.d
    ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
    ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

    mkdir -p /etc/alsa/conf.d
    ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d
    ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d

    echo repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc | sudo tee /etc/xbps.d/hyprland-void.conf
    xbps-install -Sy hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpaper hypridle hyprlock wlogout

    log "Installing additional packages"
    xbps-install -Su
    xbps-install -y "${ADDITIONAL_PKGS[@]}"

    log "Linking essential services"
    ln -s /etc/sv/dbus		        /etc/runit/runsvdir/default/
    ln -s /etc/sv/udevd		        /etc/runit/runsvdir/default/
    ln -s /etc/sv/sshd		        /etc/runit/runsvdir/default/
    ln -s /etc/sv/sddm		        /etc/runit/runsvdir/default/
    ln -s /etc/sv/wpa_supplicant	/etc/runit/runsvdir/default/
    ln -s /etc/sv/dhcpcd		    /etc/runit/runsvdir/default/
    ln -s /etc/sv/elogind	        /etc/runit/runsvdir/default/
    ln -s /etc/sv/alsa              /etc/runit/runsvdir/default/

    log "Chroot setup complete."
fi
