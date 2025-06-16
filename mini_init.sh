#!/bin/sh
# Mini_init for embedded devices
# Originally made for Wii-Linux (https://wii-linux.org)
# Copyright (C) 2025 Techflash
# Licensed under the GNU General Public License, version 2.0.

# mount filesystems
mountpoint -q /proc || mount -t proc proc /proc
mountpoint -q /tmp  || mount -t tmpfs tmpfs /tmp
mountpoint -q /sys  || mount -t sysfs sys /sys
mountpoint -q /run  || mount -t tmpfs run /run
mountpoint -q /dev  || mount -t devtmpfs dev /dev

# redirect stdio
exec > /dev/tty1 2>/dev/tty1 < /dev/tty1


echo "mini_init starting..."

# sane terminal
export TERM=linux

# sane PATH
# Arch symlinks /sbin -> /bin, /usr/sbin -> /usr/bin, and /bin -> /usr/bin,
# so we don't need to repeat ourselves with any of the symlinks
export PATH=/usr/bin:/usr/local/bin

# same HOME (we are root)
export HOME=/root

# set system hostname
cat /etc/hostname > /proc/sys/kernel/hostname

# load the wifi driver
modprobe b43

# set the date
hwclock --hctosys

# start wpa_supplicant
supp_log=/var/log/wpa_supplicant.log
wpa_supplicant -D nl80211 -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf > $supp_log 2> $supp_log &

# start net_setup (it'll wait until the wifi i/f is up)
net_log=/var/log/net_setup.log
/usr/local/bin/net_setup.sh > $net_log 2> $net_log &

# enable zram swap
modprobe zram
zramctl -a lzo /dev/zram0 -s 64M
/var/lib/wii-linux/zram-setup.sh /dev/zram0 > /dev/null

# start a shell on tty1 in /root
cd /root
setsid bash

# setsid eats our terminal, grab it back
exec > /dev/tty1 2>/dev/tty1 < /dev/tty1

# cleanup function
cleanup() {
	killall wpa_supplicant

	# absolutely 0 chance that it's still running
	# (it exits when finished), but just in case
	killall -9 net_setup.sh

	sleep 1

	# in case it's still alive
	killall -9 wpa_supplicant

	# flush the cache
	sync

	# unmount sub filesystems (except /proc, we need that)
	umount /dev /sys /tmp /run

	# rootfs goes read-only so nothing else gets written
	mount -o remount,ro /
	sync # be extra sure
}

# shell exited, what do you want to do?
while true; do
	echo '[p]oweroff, [r]eboot, [s]hell ?'

	# I would read -n 1 here but that's a bashism
	read -r action

	case $action in
		p) cleanup; echo o > /proc/sysrq-trigger ;;
		r) cleanup; echo b > /proc/sysrq-trigger ;;
		s) setsid bash; exec > /dev/tty1 2>/dev/tty1 < /dev/tty1 ;;
	esac
done
