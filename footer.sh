#Persist configuration changes
/usr/sbin/etc_tools p

#restart udev

killall udevd
killall udevtrigger
/etc/init.d/udev

#Delete this script so that it only runs once
rm -- "$0"
