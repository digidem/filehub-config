# Add a swapfile on the data store drive
# (rsync needs this for large file copies)

sed -i 's/SWAP=noswap/SWAP=swap/' /etc/firmware

cat <<'EOF' > /etc/init.d/swap
STORE_DIR=/filehub
CONFIG_DIR="$STORE_DIR"/config
LOG_DIR="$STORE_DIR"/log
rm -f /tmp/swapinfo

while read device mountpoint fstype remainder; do
    if [ ${device:0:7} == "/dev/sd" -a -e "$mountpoint$CONFIG_DIR" ];then
            mkdir -p "$mountpoint$LOG_DIR"
            log_file="$mountpoint$LOG_DIR"/backup.log
            swapfile="$mountpoint$CONFIG_DIR"/swapfile
            if [ ! -e "$swapfile" ]; then
                dd if=/dev/zero of="$swapfile" bs=1024 count=131072
                echo "$(date) - Creating swapfile $swapfile" >> "$log_file"
                mkswap "$swapfile" >> "$log_file" 2>&1
            fi
            swapon "$swapfile" >> "$log_file" 2>&1
            if [ $? -eq 0 ]; then
                echo "$(date) - Turned on swap for $swapfile" >> "$log_file"
            else
                echo "$(date) - There was an error turning on swap" >> "$log_file"
            fi
            exit 0
    fi
done < /proc/mounts
exit 0
EOF
