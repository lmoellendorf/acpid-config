acpid-config
============

This is an acpi script for the lid open/close event to be used with acpid2 (http://tedfelix.com/linux/acpid-netlink.html)

When the lid is closed, it waits for 3 seconds and exits without action if the lid has been opened again. If the lid stayed close the script locks the screen and - on ac-power - blanks it or - on battery-power - suspends to ram.

Unlike other scripts I found on the net it does not make use of 'xhost +local:0', as this is considered to be insecure. It locks the screen of enlightenment sessions but can be configured to work with kde-4/kde-3/gnome/xscreensaver/xdg-screensaver/slock. Suspend to RAM also works without X session running.

To use it install acpid2 and put the files into /etc/acpi.

First published on Gentoo Forum: http://forums.gentoo.org/viewtopic-p-7063102.html

http://forums.gentoo.org/viewtopic-p-7063102.html
