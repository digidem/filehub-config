#!/bin/sh
# Stops external network access to the device, increases security.

# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/rc.local

cat <<'EOF' >> /etc/rc.local
#START_MOD
iface="apcli0"                                    

# Drop all tcp traffic incomming on iface
/bin/iptables -A INPUT -p tcp -i ${iface} -j DROP
# Drop all udp traffic incomming on iface
/bin/iptables -A INPUT -p udp -i ${iface} -j DROP                                         

# Fetch IPv6 address on iface                                        
ipv6_addr=`ifconfig ${iface} | grep inet6 | awk {'print $3'}`

# No IPv6 filter is installed, so remove IPv6 address on iface
if [ "${ipv6_addr}" != "" ]; then
  /bin/ip -6 addr del "${ipv6_addr}" dev ${iface}
fi
#END_MOD
EOF
# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/udev/script/add_usb_storage.sh

# Delete exit from end of the file
sed -i '/^exit$/d' /etc/udev/script/add_usb_storage.sh

# Add call to usb backup script after drive mounts
cat <<'EOF' >> /etc/udev/script/add_usb_storage.sh
#START_MOD
# Run backup script
/etc/udev/script/usb_backup.sh &
exit
#END_MOD
EOF

cat <<'EOF' > /etc/udev/script/usb_backup.sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

echo "running backup" >> /tmp/usb_add_info

touch /tmp/rsyncing

SD_MOUNTPOINT=/data/UsbDisk1/Volume1
PHOTO_DIR=/monitoreo/fotos
CONFIG_DIR=/monitoreo/config
MEDIA_REGEX=.*\.\(jpg\|gif\|png\|jpeg\|mov\|avi\|wav\|mp3\|aif\|wma\|wmv\|asx\|asf\|m4v\|mp4\|mpg\|3gp\|3g2\|crw\|cr2\|nef\|dng\|mdc\|orf\|sr2\|srf\)

# Check if an SD card is inserted (always mounted at the same mount point on the Rav Filehub)
check_sdcard() {
        while read device mountpoint fstype remainder; do
                if [ "$mountpoint" == "$SD_MOUNTPOINT" ]; then
                        return 1
                fi
        done < /proc/mounts
        return 0
}

# If no SD card is inserted, just exit.
check_sdcard
if [ $? -eq 0 ]; then
        exit
fi

# Get the UUID for the SD card. Create one if it doesn't already exist
uuid_file="$SD_MOUNTPOINT"/.uuid
if [ -e $uuid_file ]; then
        sd_uuid=`cat $uuid_file`
else
        sd_uuid=`cat /proc/sys/kernel/random/uuid`
        echo "$sd_uuid" > $uuid_file
fi

# Check for a mounted drive with a config dir & rsync binary
while read device mountpoint fstype remainder; do
if [ ${device:0:7} == "/dev/sd" -a $mountpoint != "$SD_MOUNTPOINT" -a -e "$mountpoint$CONFIG_DIR" -a -e "$mountpoint$CONFIG_DIR"/rsync ];then
        # Add the config dir (containing rsync binary) to the PATH
        export PATH="$mountpoint$CONFIG_DIR":$PATH
        # Organize the photos in a folder for each SD card
        target_dir="$mountpoint$PHOTO_DIR"/"$sd_uuid"
        mkdir -p $target_dir
        # Ensure that no existing rsync scripts are running
        killall rsync
        # Copy the files from the sd card to the target dir, removing the source files once copied.
        # Uses filename and size to check for duplicates
        rsync -vrum --remove-source-files --size-only --log-file /tmp/rsync_log "$SD_MOUNTPOINT"/DCIM "$target_dir"/
        if [ $? -eq 0 ]; then
                find "$SD_MOUNTPOINT"/DCIM/ -d -type f -regex "$MEDIA_REGEX" -exec rm {} \;
                find "$SD_MOUNTPOINT"/DCIM/ -d -type d -exec rmdir {} \;
        fi
fi
done < /proc/mounts

# Write memory buffer to disk
sync

echo "Backup complete" >> /tmp/usb_add_info

rm /tmp/rsyncing
exit
EOF

# Make executable
chmod +x /etc/udev/script/usb_backup.sh

# Kill rsync when a USB drive is removed

# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/udev/script/remove_usb_storage.sh

# Add call to usb backup script after drive mounts
cat <<'EOF' >> /etc/udev/script/remove_usb_storage.sh 
#START_MOD
# Kill the rsync process if the USB drive or SD card is removed
killall rsync
#END_MOD
EOF
#Persist configuration changes
/usr/sbin/etc_tools p

#restart udev

killall udevd
killall udevtrigger
/etc/init.d/udev
