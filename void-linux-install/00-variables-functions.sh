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

#----------------------------------------
# Helper Functions
#----------------------------------------
log() {
    # Timestamped log output
    printf "[%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

confirm() {
    # Ask for user confirmation
    read -rp "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) true ;;  *) false ;;
    esac
}

#----------------------------------------
# Variables
#----------------------------------------

DRIVE="/dev/sda"
HOSTNAME="void"
CRYPT_NAME="crypt"
MAPPER_PATH="/dev/mapper/$CRYPT_NAME"
MOUNTPOINT="/mnt"
LOCALE="en_US.UTF-8"
KEYFILE="/boot/volume.key"
REPO_URL="https://repo-de.voidlinux.org/current"
BTRFS_OPTS="noatime,compress=zstd,discard=async"
ADDITIONAL_PKGS=("tar" "bat" "btop" "vsv" "xz" "fzf" "ripgrep" "ghostty" "emacs-pgtk" "vim" "font-iosevka" "tealdeer" "eza" "sddm" "xorg" "elogind" "nvidia" "Thunar" "wofi" "grimshot")

# Determine partition suffix (e.g., 'p' for NVMe drives)
if [[ "$DRIVE" =~ "nvme" ]]; then
    PART_SUFFIX="p"
else
    PART_SUFFIX=""
fi
log "Using partition suffix '$PART_SUFFIX' for drive $DRIVE."
