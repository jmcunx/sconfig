#!/bin/bash
#
# backup vnstat database in case of a crash
#        copy to /usr/local/bin/bu_vnstat.sh
# for slackware, add to /usr/etc/rc.d/rc.local
# to backup database on reboot
#

f_cpfile()
{
    l_cp_ifile="$1"
    l_cp_ofile="$2"

    if test ! -f "$l_cp_ifile"
    then
	return
    fi

    if test -f "$l_cp_ofile"
    then
	if test ! -s "$l_cp_ifile"
	then
	    return
	fi
	cmp "$l_cp_ofile" "$l_cp_ifile" > /dev/null 2>&1
	if test "$?" -eq "0"
	then
	    return
	fi
    fi

    logger "INFO vnstat b/u: Backing up $l_cp_ifile"
    cp "$l_cp_ifile" "$l_cp_ofile"
    chmod 640 "$l_cp_ofile"         > /dev/null 2>&1
    chown $g_owner:$g_group "$l_cp_ofile" > /dev/null 2>&1

} # END: f_cpfile()

f_bu_slackware()
{
    l_rcvnstat="0"

    if test "`id -u`" != "0"
    then
	return
    fi
    if test ! -x "$g_rc_vnstat"
    then
	return
    fi

    if test -d "$g_dir_vnstat" -a -d "$g_dir_bu"
    then
	f_cpfile "/etc/vnstat.conf" "$g_dir_bu/vnstat.conf.$HOST"
	pgrep -u vnstat vnstat > /dev/null 2>&1
	l_rcvnstat="$?"
	if test "$l_rcvnstat" -eq "0"
	then
	    $g_rc_vnstat stop
	fi
	sleep 1
	f_cpfile "$g_dir_vnstat/vnstat.db" "$g_dir_bu/vnstat.db.$HOST"
	f_cpfile "$g_dir_vnstat/eth0"      "$g_dir_vnstat/eth0.$HOST"
	f_cpfile "$g_dir_vnstat/wlan0"     "$g_dir_vnstat/wlan0.$HOST"
	f_cpfile "$g_dir_vnstat/tun0"      "$g_dir_vnstat/tun0.$HOST"
	f_cpfile "$g_dir_vnstat/wg0"       "$g_dir_vnstat/wg0.$HOST"
	if test "$l_rcvnstat" -eq "0"
	then
	    $g_rc_vnstat start
	fi
    fi

} # END: f_bu_slackware()

#
# main
#
HOST="`uname -n | awk -F '.' '{print $1}'`"
export HOST

g_rc_vnstat="/etc/rc.d/rc.vnstat"
g_dir_vnstat="/var/lib/vnstat"
g_dir_bhome=/u/BU
if test -d /home/jmccue
then
    g_owner="jmccue"
else
    g_owner="root"
fi

if test -d "/u1/BU"
then
    g_dir_bhome="/u1/BU"
else
    if test -d "/var/BU"
    then
	g_dir_bhome="/var/BU"
    fi
fi
g_dir_bu=$g_dir_bhome/$HOST/vnstat

if test -f /etc/slackware-version
then
    f_bu_slackware
fi


exit 0
