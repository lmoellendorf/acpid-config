#! /bin/sh
# Useful acpi actions and definitions
#
# Copyright (C) 2012 Lars Moellendorf <lars[at]moellendorf[dot]eu>
# Distributed under the terms of the GNU General Public License v2
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# default display on current host
DISPLAY=":0.0"
# time in seconds to wait after lid has been closed
TIMEOUT="3"
# some broken login managers (e.g. lxdm) do not register the user in the utmp/wtmp file
# if you use such a login manager put your username here
XUSER="lars"
##
# your suspend command
# pm-utils
#SUSPEND="pm-suspend"
# plain echo to /sys or /proc file
SUSPEND="suspend_to_disk"
##
# your screen lock command:
# enlightenment)
#SCREEN_LOCK='enlightenment_remote -desktop-lock'
# or
#SCREEN_LOCK="dbus-send --print-reply=literal --dest=org.enlightenment.wm.service /org/enlightenment/wm/RemoteObject org.enlightenment.wm.Desktop.Lock"
# kde-4)
#SCREEN_LOCK='qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock'
# kde-3)
#SCREEN_LOCK='dcop kdesktop KScreensaverIface lock'
# gnome)
#SCREEN_LOCK='gnome-screensaver-command --lock'
# xscreensaver)
#SCREEN_LOCK='xscreensaver-command -lock'
# xdg-screensaver)
#SCREEN_LOCK='xdg-screensaver lock'
# slock)
SCREEN_LOCK='slock'
# light-locker
#SCREEN_LOCK='slimlock'
#PRE_SUSPEND_HOOK=/home/lars/bin/preSuspend.sh
POST_SUSPEND_HOOK=/home/lars/bin/postSuspend.sh

# to syslog
log (){
    logger -t lid-action -- "$@"
}

# get access to X and dBus session
xsu () {
    # get the X user dynamically
    xuser="$(who | sed -ne "0,/^\([^ ]*\)[ ]*:0.*/s//\1/p")"
    log "detected X user is: $xuser"
    # check if user seems to be valid
    grep "^${xuser}:*" /etc/passwd || \
        log "falling back to static username $XUSER"; \
        xuser=$XUSER
    if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        # Looks like we are outside X
        home=$(awk -v user=${xuser} -F":" '{if ($1 == user) {print $6}}' /etc/passwd)
        log "home is: $home"
        # Get the latest file in session-bus directory
        dbus_file=$(ls $home/.dbus/session-bus/ -t | head -1)
        log "dbus file is: $dbus_file"
        # and export a variable from it
        log "source $home/.dbus/session-bus/$dbus_file"
        . "$home/.dbus/session-bus/$dbus_file" && export DBUS_SESSION_BUS_ADDRESS
    fi
    log "dbus session address is: $DBUS_SESSION_BUS_ADDRESS"
    log "su -c \"DISPLAY=$DISPLAY $@\" $xuser"
    su -c "DISPLAY=$DISPLAY $@&" $xuser
}

# suspend
suspend_to_x () {
    # $1: mem/disk
    # $2: 3/4
    # $3: pm-suspend/pm-hibernate
    ${PRE_SUSPEND_HOOK}
    # look for /sys file
    if [[ -e /sys/power/state ]]
    then
        log "echo -n $1 > /sys/power/state"
        echo -n $1 > /sys/power/state
    elif [[ -e /proc/acpi/sleep ]]
    then
        # try deprecated /proc/acpi file
        log "echo $2 > /proc/acpi/sleep"
        echo $2 > /proc/acpi/sleep
    else
        # try to invoke pm-utils
        log "$3"
        $3
    fi
    ${POST_SUSPEND_HOOK}
}

# suspend to disk
suspend_to_disk () {
  suspend_to_x disk 4 pm-hibernate
}

# suspend to ram
suspend_to_ram () {
  suspend_to_x mem 3 pm-suspend
}
