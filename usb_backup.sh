# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/udev/script/add_usb_storage.sh

# Delete exit from end of the file
sed -i '/^exit$/d' /etc/udev/script/add_usb_storage.sh

# Add call to usb backup script after drive mounts
cat <<'EOF' >> /etc/udev/script/add_usb_storage.sh
#START_MOD
# Run backup script
/etc/udev/script/usb_backup.sh
exit
#END_MOD
EOF

cat <<'EOF' > /etc/udev/script/usb_backup.sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

touch /tmp/rsyncing

SD_MOUNTPOINT=/data/UsbDisk1/Volume1
PHOTO_DIR=/monitoreo/fotos
CONFIG_DIR=/monitoreo/config

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
        # Copy the files from the sd card to the target dir, removing the source files once copied.
        # Uses filename and size to check for duplicates
        rsync -vrum --remove-source-files --size-only --log-file /tmp/rsync_log "$SD_MOUNTPOINT"/DCIM "$target_dir"/
fi
done < /proc/mounts

# Write memory buffer to disk
sync

rm /tmp/rsyncing
EOF
