#!/bin/bash
#
# Place in dir /lib64/elogind/system-sleep
# on 64 bit systems, 32 bit, maybe /lib/ ?
#
# Edit /etc/elogind/logind.conf  (slackware 15.0)
# maybe add this line to disable sleep lid:
#     HandleLidSwitch=ignore

#--- change to suite your needs,
#    most people would use /usr/local/bin
#    needed for: bt_slackware.sh
g_jmc_local="/opt/jmc/bin"

#--- wireguard settings, in case you use wireguard
g_dev_wg="wg0"
g_wgcfg="/etc/wireguard/$g_dev_wg.conf"

case $1/$2 in
    pre/*)
        logger "INFO ELOGIN: processing $1/$2 SLEEP"
        if test -x $g_jmc_local/bt_slackware.sh
        then
	    $g_jmc_local/bt_slackware.sh SLEEP
        fi
	if test -x /usr/bin/wg-quick -a -f "$g_wgcfg"
	then
	    /sbin/ip a show $g_dev_wg > /dev/null 2>&1
	    if test "$?" -eq "0"
	    then
		logger "INFO ELOGIN: stopping wireguard"
		/usr/bin/wg-quick down "$g_wgcfg"
	    fi
	fi
        ;;
    post/*)
        logger "INFO ELOGIN: submitting $1/$2 RESUME"
        if test -x $g_jmc_local/bt_slackware.sh
        then
            $g_jmc_local/bt_slackware.sh RESUME &
        fi
        ;;
esac
