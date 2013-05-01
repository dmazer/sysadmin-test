#!/bin/bash
# pxe script - 2012-12-08  04:39:26 AM

USAGE="Usage: ${0##*/} [ -c choose isos][-s start pxe serving][ -f stop ]"

[ ! "$1" ] && { echo "$USAGE" ;exit; }

uuid=5e830673-e5c8-48d4-8f61-0ecac8bc5e32
DIR=/2t/VMs/ISO
DIR2=/2t/VMs/crb
ISOs="
CentOS-6.3-x86_64-minimal.iso
CentOS-6.3-x86_64-bin-DVD1.iso
ubuntu-12.04-server-amd64.iso
crowbar-v1.5-openstack_master.iso
CentOS-6.3-x86_64-LiveCD.iso
"
[ "$1" = start -o "$1" = stop ] && { ac=$1 ; }

while getopts escflpxm?h o
do  case "$o" in
      s) ac=start ;; 
      l) seelog=1 ;; 
      m) mountonly=1 ;; 
      x) startpxe=1 ;; 
      f) ac=stop ;; 
      c) choose=1 ;; 
      p) ps=1 ; break ;; 
			e) vie ${0##*/} ; exit ;;
      [?]|h)  echo "$USAGE"; exit ;;
      *) break ;;
      esac
done
shift $(($OPTIND-1))

mountdir=ubuntu_dvd
mountdir=centos

if [ "$ps" ] ;then
	r="$(/bin/df -h | grep $mountdir)"
	p=$(ps -ef|egrep "tftp|dhcp|root.*apache"|grep -v grep)
	[ ! "$r" -a ! "$p" ] && exit
	echo "$p"
	echo "====="
	sudo blkid $(sudo losetup -a|cut -d'(' -f2|sed 's/)//')|cut -d'"' -f2
	sudo losetup -a|awk '{print $3}'|sed -e 's/(//' -e 's/)//'
	echo "$r"
	exit
fi

log=/tmp/pxe.log
[ ! -d /var/www/$mountdir ] && sudo mkdir /var/www/$mountdir

if [ "$ac" = start ] ; then
	sudo mount /2t 2>/dev/null
	if [ "$choose" -o ! "$ISO" ] ; then
		echo "$ISOs"|grep iso|cat -n
		echo -en "\n (q) : " ; read ans
		test "$ans" = q && exit
		ISO=$(echo "$ISOs"|grep iso|sed -n ${ans}p)
  fi	
	[ -f $DIR/$ISO ] && iso=$DIR/$ISO
	[ -f $DIR2/$ISO ] && iso=$DIR2/$ISO
	echo -en "\nmounting $iso ..." ; sleep 1 ; echo
	r="$(/bin/df -h|grep cent|grep -v grep|awk '{print $1}')"
	[ "$r" ] && { echo "$r"|while read d; do sudo umount "$d" ; done ; }
	[ "$mountonly" ] && exit
	sudo mount -oloop $iso /var/www/$mountdir >> $log 2>&1
	sudo mount -oloop $iso /tftpboot/$mountdir >> $log 2>&1
sudo /etc/init.d/isc-dhcp-server $ac > $log 2>&1
sudo service tftpd-hpa $ac >> $log 2>&1
sudo /etc/init.d/apache2 $ac >> $log 2>&1
	[ "$startpxe" ] && VBoxManage startvm $uuid
elif [ "$ac" = stop ] ; then
	sudo umount /var/www/$mountdir >> $log 2>&1
sudo /etc/init.d/isc-dhcp-server $ac > $log 2>&1
sudo service tftpd-hpa $ac >> $log 2>&1
sudo /etc/init.d/apache2 $ac >> $log 2>&1
fi

r=$(ps -ef|egrep "root.*apache|tftp|dhcp"|grep -v grep)
[ ! "$r" ] && echo dhcp tftp apache stopped || { /bin/df -h |/bin/grep loop; echo -e "\n$r" ; }

[ "$seelog" ] && grep -v done "$log" | less
