#!/bin/bash
# blck script - 2013-04-30  08:56:19 AM

[ ! "$1" ] && { echo "Usage:  $0 ipaddr " ;exit; }

BLISTS="
    cbl.abuseat.org
    dnsbl.sorbs.net
    bl.spamcop.net
    zen.spamhaus.org
    combined.njabl.org
"

ERROR() {
  echo $0 ERROR: $1 >&2
  exit 2
}

reverse=$(echo $1 |
  sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")

REVERSE_DNS=$(dig +short -x $1)

bl=0
for BL in ${BLISTS} ; do

    printf $(env TZ=UTC date "+%Y-%m-%d_%H:%M:%S_%Z")
    printf "%-40s" " ${reverse}.${BL}."

    LISTED="$(dig +short -t a ${reverse}.${BL}.)"
		if [ "${LISTED#*127.0.0*}" != "$LISTED" ] ; then
		 ((bl=bl+1))	
		fi
    echo ${LISTED:----}

done

if [ $bl -gt 0 ] ; then
	echo -e "\nYou have $bl blacklist(s)\n"
else
	echo -e "\nNo blacklists for $1\n"
fi
