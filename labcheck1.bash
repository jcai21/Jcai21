#!/bin/bash
#  OPS535 Lab 1 configuration check
#  Written by: Peter Callaghan
#  Last Modified: 18 Jan, '19
#  This script runs a series of commands to show the current configuration of the machine it is run on
#  Run it on your host and each VM, and attach the output to the lab submission.

if [ `getenforce` != "Enforcing" ]
then
	echo "SELinux is not currently enforcing on this machine.  Turn it back on, and do not turn it off again." >&2
	exit 2
fi

#Ensure the host name has been set correctly
date
echo
echo "hostname:"`hostname`
echo
echo "SELinux status:"`getenforce`
echo

echo INTERFACES
cat /etc/sysconfig/network-scripts/ifcfg-*
echo

echo "Firewall configuration"
for zone in `firewall-cmd --get-active-zones | sed -r '/^[[:space:]]+/ d'`
do
	firewall-cmd --zone=$zone --list-all
	echo
done
echo
echo Direct Rules
firewall-cmd --direct --get-all-rules
echo

filesystem=`df | grep centos-root | cut -d' ' -f1`
echo "UUID:"`blkid $filesystem | sed -r 's/^.*UUID="([-a-zA-Z0-9]+)".*$/\1/'`
echo

if [ "`hostname -s`" == "host" ]
then
	echo "Virtual Networks"
	for virbr in `virsh net-list | sed -re '1,2 d' -e 's/[[:space:]]+/ /g' -e 's/^ //' | cut -f1 -d' '`
	do
		virsh net-dumpxml $virbr
	done

	echo "Virtual Machine Networks"
	for machine in `virsh list --all | sed -re '1,2 d' -e 's/[[:space:]]+/ /g' -e 's/^ //' | cut -f2 -d' '`
	do
		echo $machine
		virsh dumpxml $machine | sed -r '/<interface type=/,/<\/interface>/ ! d'
		echo
	done
fi

echo "Routes"
ip route show
echo
