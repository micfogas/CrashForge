#!/bin/sh
EXE=guiderII-arm
KERNEL=uImage-guider*
LOG=guiderII-log-pwn.log
M3HEX=GuiderII.hex
MYDAEMON=mydaemon.out
MACHINE=guiderII
MACHINE_ARCH=armv5tejl

# Get the working directory
WORKDIR=$(cd `dirname $0`; pwd)
# Set the log
LOG=$WORKDIR/$LOG
# Clear the old logs
rm $LOG
# Post the current workdir into the log
echo "WORKDIR="$WORKDIR >> $LOG

# Tell user to wait on LCD
echo "Display wait on lcd" >> $LOG
if [ -f $WORKDIR/start.bmp ]
then
  cat $WORKDIR/start.bmp > /dev/fb0
fi

# Reset root pw
if [ -f $WORKDIR/scripts/run/root.sh ]
then
  source $WORKDIR/scripts/run/root.sh
fi

# Install SSHD
if [ -f $WORKDIR/scripts/run/sshd.sh ]
then
  source $WORKDIR/scripts/run/sshd.sh
fi

# Install Updated Busybox and Netcat
if [ -f $WORKDIR/scripts/run/busybox.sh ]
then
  source $WORKDIR/scripts/run/busybox.sh
fi

# Install Samba
#if [ -f $WORKDIR/scripts/run/samba.sh ]
#then
#  source $WORKDIR/scripts/run/samba.sh
#fi

sync

sleep 1

echo "Flash Forge Cloud Switch OFF" >> $LOG
sed -i '1c OFF' /opt/flashforge/cloud-ff
sync

echo "Ethernet MAC Set" >> $LOG
find $WORKDIR/mac_addrs -type f -print0 | xargs -0 dos2unix
Ethernet_MAC=`sed -n '/ifconfig eth0 hw ether/p' /etc/init.d/rcS | cut -d ' ' -f5 | grep -E '[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}'`
echo "Ethernet_MAC="$Ethernet_MAC >> $LOG

if [ ! $Ethernet_MAC ]; then
	MAC_ADDR_H=`sed -n '1p' $WORKDIR/mac_addrs`
	echo "None MAC MAC_ADDR_H="$MAC_ADDR_H >> $LOG
	
	if [ $MAC_ADDR_H ]; then
		sed -i '/ifconfig/d' /etc/init.d/rcS
		sed -i '3a ifconfig eth0 hw ether '"$MAC_ADDR_H" /etc/init.d/rcS
		sync
	else
		echo "None MAC Address or \"mac_addrs\" file" >> $LOG
#                exit -1
#		halt -f
	fi
	
	MAC_ADDR_R=`sed -n '2p' $WORKDIR/mac_addrs`
	echo "None MAC MAC_ADDR_R="$MAC_ADDR_R >> $LOG
	
	if [ "$MAC_ADDR_R" \> "$MAC_ADDR_H" ]; then
		machex=`awk 'BEGIN{FS=OFS=":";$0=ARGV[1];$NF=sprintf("%.2X",("0x"$NF)+1);print}' $MAC_ADDR_H`
		echo "machex="$machex >> $LOG
		sed -i '1c '"$machex" $WORKDIR/mac_addrs
		sync
	else
		rm -f $WORKDIR/mac_addrs
		sync
	fi
	
	find /etc/init.d/rcS -type f -print0 | xargs -0 dos2unix
	echo "Ethernet MAC Set Success" >> $LOG
else
	MAC_ADDR_H=`sed -n '1p' $WORKDIR/mac_addrs`
	echo "Has MAC MAC_ADDR_H="$MAC_ADDR_H >> $LOG
	
	MAC_ADDR_R=`sed -n '2p' $WORKDIR/mac_addrs`
	echo "Has MAC MAC_ADDR_R="$MAC_ADDR_R >> $LOG
	
	if [ "$Ethernet_MAC" \> "$MAC_ADDR_H" ]; then
		machex=`awk 'BEGIN{FS=OFS=":";$0=ARGV[1];$NF=sprintf("%.2X",("0x"$NF)+1);print}' $Ethernet_MAC`
		echo "machex="$machex >> $LOG
		sed -i '1c '"$machex" $WORKDIR/mac_addrs
		sync
	fi
	if [ "$Ethernet_MAC" \> "$MAC_ADDR_R" ]; then
		rm -f $WORKDIR/mac_addrs
		sync
	fi
fi
sync
sleep 1
echo "RSA cryptographic keys" >> $LOG
rm -rf /opt/openssl-1.0.2d-none/bin/key*
sed -i '1c OFF' /opt/flashforge/cloud-username-pin
sed -i '4d' /opt/flashforge/cloud-username-pin
sync

if [ ! -f /opt/openssl-1.0.2d-none/bin/key.priv ]; then
	echo 'abcde' | ssh-keygen -t rsa -b 2048 -f /opt/openssl-1.0.2d-none/bin/key.priv
fi

if [ ! -f /opt/openssl-1.0.2d-none/bin/key.pub ]; then
	ssh-keygen -e -m PEM -f /opt/openssl-1.0.2d-none/bin/key.priv > /opt/openssl-1.0.2d-none/bin/key.pub
fi

sync

# Tell user it's done on LCD
echo "Display pwnd on lcd" >> $LOG
if [ -f $WORKDIR/complete.bmp ]
then
  cat $WORKDIR/complete.bmp > /dev/fb0
fi

sleep 5

# TSLIB
echo "export tslib" >> $LOG
export LD_LIBRARY_PATH=/opt/tslib-1.4-none/lib:$LD_LIBRARY_PATH
if [ -f $WORKDIR/play ]; then
	echo "play complete music" >> $LOG
	chmod a+x $WORKDIR/play
	$WORKDIR/play -qws
fi

halt -f
