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
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IFS=$'\n\t'
source 00-variables-functions.sh

#----------------------------------------
# Preliminary Checks
#----------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Confirm destructive action
log "Target drive is ${DRIVE}. All data on this drive will be erased!"
if ! confirm "Are you sure you want to continue?"; then
    log "User aborted. Exiting."
    exit 1
fi

#----------------------------------------
# Partition the Drive
#----------------------------------------
log "Partitioning ${DRIVE}..."

# Define the partitions using a scriptable input format
# 1. Partition EFI system	- 512MiB - GUID alias 'U'
# 2. Partition Linux filesystem - rest   - GUID alias 'L'
sfdisk --wipe always --label gpt "${DRIVE}" << EOF
1M,512M,U
,+,L
EOF

log "Partitioning complete: ${DRIVE}${PART_SUFFIX}1 (EFI), ${DRIVE}${PART_SUFFIX}2 (LUKS)."

#----------------------------------------
# Format EFI Partition
#----------------------------------------
log "Formatting EFI partition..."
mkfs.vfat -F32 "${DRIVE}${PART_SUFFIX}1"
log "EFI partition formatted as FAT32."

#----------------------------------------
# Set Up LUKS Encryption
#----------------------------------------
log "Setting up LUKS encryption on ${DRIVE}${PART_SUFFIX}2..."
cryptsetup luksFormat --type luks1 "${DRIVE}${PART_SUFFIX}2"
cryptsetup open     "${DRIVE}${PART_SUFFIX}2" "${CRYPT_NAME}"
log "LUKS container opened at ${MAPPER_PATH}."

#----------------------------------------
# Create Btrfs Filesystem and Subvolumes
#----------------------------------------
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

#----------------------------------------
# Mount Subvolumes and EFI
#----------------------------------------
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

#----------------------------------------
# Install Base System and Necessary Tools
#----------------------------------------
log "Installing base system and essential packages..."

mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

xbps-install -Sy -R "${REPO_URL}" -r "${MOUNTPOINT}" \
    base-system grub-x86_64-efi cryptsetup btrfs-progs emacs

cp /etc/resolv.conf "${MOUNTPOINT}/etc/"
log "Base system instaleld"

#----------------------------------------
# Generate fstab
#----------------------------------------
log "Generating fstab"
xgenfstab -U "${MOUNTPOINT}" > "${MOUNTPOINT}/etc/fstab"

#----------------------------------------
# Prepare chroot scripts
#----------------------------------------
cp "${SCRIPT_DIR}/*" "${MOUNTPOINT}/tmp/"
echo "DEBUG: Script dir: $SCRIPT_DIR"
echo "DEBUG: ls script_dir/*:"
ls ${SCRIPT_DIR}/

log "Chroot prepared in ${MOUNTPOINT} directory"
log "To chroot to system execute xchroot ${MOUNTPOINT} /tmp/02-chroot-system-setup.sh"
