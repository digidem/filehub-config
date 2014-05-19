# Add a swapfile on the data store drive 
# (rsync needs this for large file copies)

cat <<'EOF' > /etc/init.d/swap
STORE_DIR=/monitoreo
CONFIG_DIR="$STORE_DIR"/no_tocar

while read device mountpoint fstype remainder; do
    if [ ${device:0:7} == "/dev/sd" -a -e "$mountpoint$CONFIG_DIR" ];then
            local swapfile
            swapfile="$mountpoint$CONFIG_DIR"/swapfile
            if [ ! -e "$swapfile" ]; then
                dd if=/dev/zero of="$swapfile" bs=1024 count=65536
            fi
            swapon "$swapfile"
    fi
done < /proc/mounts
EOF
