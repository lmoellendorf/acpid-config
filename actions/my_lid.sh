#! /bin/sh
# Lid button pressed/released event handler
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

. /etc/acpi/actions/my_actions.sh

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
    # suspend
    execute_command $SUSPEND
else
    # AC
    log "on AC power"
    # switch-off screen
    execute_command xsu "xset dpms force off"
fi

