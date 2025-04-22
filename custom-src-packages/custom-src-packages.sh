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

## Brave Browser Nightly
BRAVE_EXIST=$(xbps-query -s brave-browser-nightly)
if [ "$BRAVE_EXIST" == "" ] 
then
    if ! [ -d ${VOID_PKG_DIR}/void-packages/srcpkgs/brave-browser-nightly ]
    then
	mkdir -p ${VOID_PKG_DIR}/void-packages/srcpkgs/brave-browser-nightly
    fi

    cd "$SCRIPT_DIR"
    cp -f ./xbps-templates/brave-browser-nightly/template ${VOID_PKG_DIR}/void-packages/srcpkgs/brave-browser-nightly/template
    cd "${VOID_PKG_DIR}/void-packages"
    ./xbps-src pkg brave-browser-nightly
    sudo xbps-install --repository hostdir/binpkgs brave-browser-nightly
else
    cd "$SCRIPT_DIR"
    CURRENT_BRAVE_VERSION=$(brave-browser-nightly --version | cut -d " " -f 3 | cut -c 5-)
    TEMPLATE_BRAVE_VERSION=$(grep ^version= xbps-templates/brave-browser-nightly/template | cut -d "=" -f 2)
    if ! [ "$CURRENT_BRAVE_VERSION" == "$TEMPLATE_BRAVE_VERSION" ]
    then
	cd "$SCRIPT_DIR"
	cp -f ./xbps-templates/brave-browser-nightly/template ${VOID_PKG_DIR}/srcpkgs/brave-browser-nightly/template
	cd "${VOID_PKG_DIR}/void-packages"
	./xbps-src pkg brave-browser-nightly
	sudo xbps-remove brave-browser-nightly
	sudo xbps-install --repository hostdir/binpkgs brave-browser-nightly
   fi
fi

