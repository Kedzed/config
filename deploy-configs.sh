#!/usr/bin/bash

if [ -e /usr/bin/emacs ] || [ -e /usr/bin/wget] || [ -e /usr/bin/tar] || [ -e /usr/bin/xz ]
then
    # Emacs config
    emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "emacs-config.org")'

    # Bash
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    rm -rf ble.sh
    emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "bashrc-config.org")'
else
    echo "[ERROR] Missing dependencies to deploy config!"
    echo
    echo "Missing:"
    if ! [ -e /usr/bin/emacs ]
    then
	echo "- Emacs"
    fi
    if ! [ -e /usr/bin/wget ]
    then
	echo "- wget"
    fi
    if ! [ -e /usr/bin/tar ]
    then	
	echo "- tar"
    fi
    if ! [ -e /usr/bin/xz ]
    then
	echo "- xz"
    fi
fi
