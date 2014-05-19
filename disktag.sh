
# Updates /etc/init.d/disktag which determines the names of disks attached via USB

cat  <<'EOF' > /etc/init.d/disktag
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.1 UsbDisk 2
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.2 UsbDisk 3
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.3 UsbDisk 4
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.4 UsbDisk 5
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.5 UsbDisk 6
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.6 UsbDisk 7
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.7 UsbDisk 8
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.8 UsbDisk 9
usb1/1-1/1-1.2/1-1.2.1 UsbDisk 2
usb1/1-1/1-1.2/1-1.2.2 UsbDisk 3
usb1/1-1/1-1.2/1-1.2.3 UsbDisk 4
usb1/1-1/1-1.2/1-1.2.4 UsbDisk 5
usb1/1-1/1-1.1 UsbDisk 1
usb1/1-1/1-1.2 UsbDisk 2
usb1/1-1/1-1.3 UsbDisk 3
usb2/2-1/2-1.1 UsbDisk 1
usb2/2-1/2-1.2 UsbDisk 2
usb2/2-1/2-1.3 UsbDisk 3
EOF
