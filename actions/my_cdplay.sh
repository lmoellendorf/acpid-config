#! /bin/sh
# Multimedia keys event handler
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

event=$1

# to syslog
log (){
    logger -t $event-action -- "$@"
}

case "$2" in
    "CDNEXT" )
        mpc | grep '\[.*\]'
        if [ $? -eq 1 ]
        then
            log mpc toggle
            mpc toggle
        else
            log mpc next
            mpc next
        fi
        ;;
    "CDPREV" )
        mpc | grep '\[.*\]'
        if [ $? -eq 1 ]
        then
            log mpc toggle
            mpc toggle
        else
            log mpc prev
            mpc prev
        fi
        ;;
    "CDPLAY" )
        log mpc toggle
        ;;
esac
