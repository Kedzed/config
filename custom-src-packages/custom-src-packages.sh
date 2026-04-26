#!/usr/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VOID_PKG_DIR="$HOME/.local/share"

# Prepare void-packages folder
if ! [ -d ${VOID_PKG_DIR} ]
then
    mkdir -p ${VOID_PKG_DIR}
fi

cd "$VOID_PKG_DIR"
if [ -d ${VOID_PKG_DIR}/void-packages ]
then
    cd void-packages
    ./xbps-src bootstrap-update
else
    git clone --depth=1 https://github.com/void-linux/void-packages.git
    cd void-packages
    ./xbps-src binary-bootstrap
fi

# Check for restricted flag in conf and add it
RES=$( rg XBPS_ALLOW_RESTRICTED etc/conf )
if [ "$RES" == "" ]
then
   echo XBPS_ALLOW_RESTRICTED=yes >> etc/conf
fi

# Install custom packages

## Discord (nonfree)
DISCORD_QUERY=$(xbps-query -s discord)
if [ "$DISCORD_QUERY" == "" ]
then
    cd "${VOID_PKG_DIR}/void-packages"
    ./xbps-src pkg discord
    sudo xbps-install --repository hostdir/binpkgs/nonfree discord
fi
