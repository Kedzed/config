#!/usr/bin/bash

if [ -e /usr/bin/emacs ]
then
    # Emacs config
    emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "emacs-config.org")'

    # Bash
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    rm -rf ble.sh
    emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "bashrc-config.org")'

    # Sway
    emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "sway-config.org")'

    # Hyprland
    emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "hyprland-config.org")'

    # Waybar
    emacs --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "waybar-config.org")'
else
    echo "[ERROR] Missing emacs to tangle configs!"
fi
