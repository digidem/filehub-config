# Add a swapfile on the data store drive 
# (rsync needs this for large file copies)

sed -i 's/SWAP=noswap/SWAP=swap/' /etc/firmware

cat <<'EOF' > /etc/init.d/swap
STORE_DIR=/monitoreo
CONFIG_DIR="$STORE_DIR"/no_tocar
rm -f /tmp/swapinfo

while read device mountpoint fstype remainder; do
    if [ ${device:0:7} == "/dev/sd" -a -e "$mountpoint$CONFIG_DIR" ];then
            swapfile="$mountpoint$CONFIG_DIR"/swapfile
            if [ ! -e "$swapfile" ]; then
                dd if=/dev/zero of="$swapfile" bs=1024 count=65536
                echo "Creating swapfile $swapfile" >> /tmp/swapinfo
            fi
            swapon "$swapfile" >> /tmp/swapinfo 2>&1
            if [ $? -eq 0 ]; then
                echo "Turned on swap for $swapfile" >> /tmp/swapinfo
            else
                echo "There was an error turning on swap" >> /tmp/swapinfo
            fi
            exit 0
    fi
done < /proc/mounts
exit 0
EOF
