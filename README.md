RAVPower Automation
===================

This collection of scripts automate functionality for copying and backing up files using a [RAVPower Filehub](http://www.ravpower.com/ravpower-rp-wd01-filehub-3000mah-power-bank.html).

- [x] Change the default password
- [x] Block external network access
- [x] Copy files from SD Card to USB drive automatically
- [ ] Rename & organize files using EXIF data
- [ ] Backup / sync between two USB drives

How to hack the Filehub embedded Linux
--------------------------------------

The RAVPower Filehub runs embedded Linux, which is a cut-down version of Linux with a low memory footprint. Most of the filesystem is read-only apart from the contents of `/etc` and `/tmp`, but changes are not persisted across reboots.

The easiest way to "hack" / modify the configuration of the embedded Linux is to create a script `EnterRouterMode.sh` on an SD card and put the card in the Filehub. The current firmware (2.000.004) will execute a script with this name with root permissions when the SD card is mounted.

The `EnterRouterMode.sh` script modifies scripts within `/etc` and persists changes by running `/usr/sbin/etc_tools p`.

To use, download the EnterRouterMode.sh script, copy it to the top-level folder of an SD card, and insert it into the filehub device.

Building from source
--------------------

```shell
git clone https://github.com/digidem/filehub-config.git
make
```

Change the default password
---------------------------

The default root password on RAVPower Filehub devices is 20080826. This is available on several online forums. Best change it. You can do this by telnet (username: root password: 20080826):

```shell
telnet 10.10.10.254
passwd
```

or create a file `EnterRouterMode.sh` on an SD card and insert it into the Filehub:

```shell
#!/bin/sh
passwd <<'EOF'
newpassword
newpassword
EOF
/usr/sbin/etc_tools p
```

Block external network access
-----------------------------

By default it is possible to telnet into the Filehub from an external network if you know what you are doing. This script adds iptables rules to `/etc/rc.local` ([source](http://www.isartor.org/wiki/Making_the_RavPower_Filehub_RP-WD01_work_with_non-free_hotspots))

Copy files from SD card automatically
-------------------------------------

The script runs when any USB device is attached. It checks whether an SD card is present, and it looks for an external USB drive (can be a thumb drive or a USB disk drive) with a folder `/monitoreo/config` which contains an [rsync](http://rsync.samba.org/) binary built for embedded linux. There is not enough memory on the filehub device to store the rsync binary on the device itself.

The script uses rsync to copy files, which should be resilient to interuption mid-copy and resume where it left off. Source files are removed from the SD card as they are copied to the external drive.

A folder is created for each SD card, identified by a [UUID](http://en.wikipedia.org/wiki/Universally_unique_identifier). It would be ideal to use the serial number for an SD card for the UUID, but unfortunately it is not possible to access this. `udevadm info -a -p  $(udevadm info -q path -n /dev/sda) | grep -m 1 "ATTRS{serial}" | cut -d'"' -f2` returns the serial number for the card reader, rather than the SD card. Instead we generate a UUID using `cat /proc/sys/kernel/random/uuid` and store that on the SD card. Bear in mind if an SD card is re-formatted in the camera then this UUID will be lost, so the card will appear as a new card next time it is inserted. Using a UUID allows for transfers to be interupted and resumed later.

When the SD card or USB drive is removed, we kill the rsync process, otherwise it hangs around.

