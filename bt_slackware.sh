#!/bin/bash
#
# bt_slackware.sh
#    bluetit wrapper to start/stop bluetit on Slackware 15.0+
#    Will wait for the network to start
#
# >>> Set variable g_user_01 below to
#     the user you want to enable xscreensaver
#
# script /lib64/elogind/system-sleep/10_sleep.sh
# is needed something like what is below.
# Notice the '&' on RESUME.  This should be submitted to
# background because it will wait for an active Network
#
#------------------------------------------------START
#    case $1/$2 in
#        pre/*)
#            if test -x /usr/local/bin/bt_slackware.sh
#            then
#                /usr/local/bin/bt_slackware.sh SLEEP
#            fi
#            ;;
#        post/*)
#            if test -x /usr/local/bin/bt_slackware.sh
#            then
#                /usr/local/bin/bt_slackware.sh RESUME &
#            fi
#            ;;
#    esac
#------------------------------------------------END
#
# and in /etc/rc.d/rc.local
# add something like this, but notice the '&'
# This should be submitted to background because
# it will wait for an active Network
#------------------------------------------------START
#    if test -x /usr/local/bin/bt_slackware.sh
#    then
#        /usr/local/bin/bt_slackware.sh START &
#    fi
#------------------------------------------------END
#
# and in /etc/rc.d/rc.local_shutdown
# add something like this
#------------------------------------------------START
#    if test -x /usr/local/bin/bt_slackware.sh
#    then
#        /usr/local/bin/bt_slackware.sh STOP
#    fi
#------------------------------------------------END
#
# You can edit /etc/elogind/logind.conf
#  add this line to disable sleep lid:
#     HandleLidSwitch=ignore
# to prevent sleep on lid close
#

set -o pipefail

#
# f_net_stat() - wait for network to be active
#
f_net_stat()
{
    l_interface="$1"
    l_max="20"
    l_count="0"

    while test "$l_count" -le "$l_max"
    do
	logger "INFO BT: network check, try $l_count"
	$g_prog_ip link show "$l_interface" 2> /dev/null \
	    | grep 'state UP' > /dev/null 2>&1
	if test "$?" -eq "0"
	then
	    g_active="Y"
	    logger "INFO BT: network for $l_interface is active"
	    return
	fi
	let l_count=l_count+1
	sleep 3
    done

} # END: f_net_stat()

#
# f_bt_stop() - stop Linux Suite
#
f_bt_stop()
{
    l_base_goldcrest=`basename $g_prog_goldcrest`

    if test -x "$g_prog_goldcrest"
    then
	logger "INFO BT STOP: stopping VPN"
	pgrep $l_base_goldcrest > /dev/null 2>&1
	if test "$?" -eq "0"
	then
	    logger "INFO BT STOP: stopping goldcrest"
	    pkill -TERM $l_base_goldcrest > /dev/null 2>&1
	    sleep 1
	fi
	pgrep $l_base_goldcrest > /dev/null 2>&1
	if test "$?" -eq "0"
	then
	    pkill -TERM $l_base_goldcrest > /dev/null 2>&1
	    sleep 1
	    killall $l_base_goldcrest > /dev/null 2>&1
	    sleep 1
	fi
	if test -x "$g_rc_bluetit"
	then
	    $g_rc_bluetit status | grep 'not running' > /dev/null 2>&1
	    if test "$?" -ne "0"
	    then
		logger "INFO BT STOP: stopping bluetit"
		$g_rc_bluetit stop
	    else
		logger "INFO BT STOP: bluetit not active, cannot stop"
	    fi
	fi
	logger "INFO BT STOP: DONE stopping VPNs"
    fi

} # END: f_bt_stop()

#
# f_bt_sleep() - start screen saver and stop VPN related objects
#
f_bt_sleep()
{
    logger "INFO BT SLEEP: START sleep"

    #--- one of these for each user
    if test -d "/home/$g_user_01"
    then
	pgrep -u "$g_user_01" xscreensaver > /dev/null 2>&1
	if test "$?" -eq "0"
	then
	    su $g_user_01 -c "(xscreensaver-command -lock)" &
	    sleep 1
	fi
    fi

    f_bt_stop
    logger "INFO BT SLEEP: DONE sleep"

} # END: f_bt_sleep()

#
# f_bt_start() -- start bluetit, will wait for network to be active
#
f_bt_start()
{
    if test -x "$g_rc_bluetit"
    then
	$g_rc_bluetit status | grep 'not running' > /dev/null 2>&1
	if test "$?" -eq "0"
	then
	    f_net_stat "$g_interface"
	    if test "$g_active" = "N"
	    then
		logger "ERROR BT: network down, cannot start bluetit"
	    else
		logger "INFO BT: starting bluetit"
		$g_rc_bluetit start
	    fi
	else
	    logger "WARN BT: cannot start bluetit, already executing"
	fi
    fi

} # END: f_bt_start()

#
# main
#
g_sname="$0"
g_rmode="$1"
g_interface="wlan0"
g_active="N"
g_prog_ip="/sbin/ip"
g_rc_bluetit="/etc/rc.d/init.d/bluetit"
g_prog_goldcrest="/usr/local/bin/goldcrest"
g_user_01="jmccue"

if test ! -x "$g_prog_ip"
then
    logger "ERROR BT: missing prog $g_prog_ip"
    g_rmode="error"
fi

case "$g_rmode" in
    "SLEEP")
	f_bt_sleep
	;;
    "STOP")
	f_bt_stop
	;;
    "START")
	f_bt_start
	;;
    "RESUME")
	f_bt_start
	;;
    *)
	logger "ERROR BT: $g_rmode invalid mode for $g_sname"
	;;
esac

