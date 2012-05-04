#! /bin/sh
# lid button pressed/released event handler

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
SUSPEND="suspend_to_ram"
##
# your screen lock command:
# enlightenment)
SCREEN_LOCK='enlightenment_remote -desktop-lock'
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
#SCREEN_LOCK='slock'

# to syslog
log (){
    logger -t lid-action -- "$@"
}

# get access to X and dBus session
xsu () {
    # get the X user dynamically
    xuser="$(who | sed -ne "s/^\([^ ]*\)[ ]*:0.*/\1/p")"
    log "detected X user is: $xuser"
    if [[ -z "$xuser" ]]; then
        # fallback to static username
        xuser=$XUSER
    fi
    if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        # Looks like we are outside X
        home=$(grep $xuser /etc/passwd)
        home=${home#*:*:*:*:*:}
        home=${home%:*}
        log "home is: $home"
        # Get the latest file in session-bus directory
        dbus_file=$(ls $home/.dbus/session-bus/ -t | head -1)
        log "dbus file is: $dbus_file"
        # and export a variable from it
        log "source $home/.dbus/session-bus/$dbus_file"
        . "$home/.dbus/session-bus/$dbus_file" && export DBUS_SESSION_BUS_ADDRESS
    fi
    log "dbus session address is: $DBUS_SESSION_BUS_ADDRESS"
    log "su -l -c \"DISPLAY=$DISPLAY $@\" $xuser"
    su -l -c "DISPLAY=$DISPLAY $@" $xuser
}

# suspend to ram
suspend_to_ram () {
    # look for /sys file
    if [[ -e /sys/power/state ]]
    then
        log "echo -n mem > /sys/power/state"
        echo -n mem > /sys/power/state
    elif [[ -e /proc/acpi/sleep ]]
    then
        # try deprecated /proc/acpi file
        log "echo 3 > /proc/acpi/sleep"
        echo 3 > /proc/acpi/sleep
    else
        # try to invoke pm-utils
        log "pm-suspend"
        pm-suspend
    fi
}

# pass the command you want to execute on lid close to this function
execute_command () {
    # this script only cares for LID close events
    if [ "$close" == "close" ]
    then
        ## now sleep for a while and then check if the user decided
        ## to open the lid again
        #
        #acpi_listen -t $TIMEOUT
        # the above won't work since this script blocks acpid
        # so acpi_listen would not report any events while this
        # script is executed
        sleep $TIMEOUT
        STATUS=$(</proc/acpi/button/lid/LID/state)

        if [ "${STATUS##* }" == "open" ]
        then
            log "on-lid-close-action interrupted"
        else
            # lock screen
            log "locking screen"
            xsu "$SCREEN_LOCK"
            # take action
            log "$@"
            ERROR=$( { "$@"; } 2>&1 )
            log "$ERROR"

        fi
    fi
}

log "$@"
# close or open?
close=$3
# check if we are on ac- or on battery-power
on_ac_power
if [ $? -ne 0 ]
then
    # BATTERY
    log "on battery power"
    # suspend to ram
    execute_command $SUSPEND
else
    # AC
    log "on AC power"
    # switch-off screen
    execute_command xsu "xset dpms force off"
fi

