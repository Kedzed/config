#!/bin/sh
nm-applet    2>&1 > /dev/null &
killall nm-applet
