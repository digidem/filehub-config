
# Kill rsync when a USB drive is removed

# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/udev/script/remove_usb_storage.sh

# Add call to usb backup script after drive mounts
cat <<'EOF' >> /etc/udev/script/remove_usb_storage.sh 
#START_MOD
# Kill the rsync process if the USB drive or SD card is removed
if [ -e /tmp/backup.pid ]; then
        kill $(cat /tmp/backup.pid)
        rm /tmp/backup.pid
fi

# Turn off swap if the store drive is removed
STORE_DIR=/monitoreo
CONFIG_DIR="$STORE_DIR"/no_tocar

# Check if a USB drive is attached which is initialize for storing monitoring data
check_storedrive() {
        while read device mountpoint fstype remainder; do
        if [ ${device:0:7} == "/dev/sd" -a -e "$mountpoint$CONFIG_DIR"/rsync ];then
                return 1
        fi
        done < /proc/mounts
        return 0
}

# If the store drive is no longer attached, turn off swap
check_storedrive
if [ $? -eq 0 ]; then
    swapoff "$mountpoint$CONFIG_DIR"/swapfile
fi

#END_MOD
EOF
