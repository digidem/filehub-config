RAVPower Automation
===================

This collection of scripts automate functionality for copying and backing up files using a [RAVPower Filehub](http://www.ravpower.com/ravpower-rp-wd01-filehub-3000mah-power-bank.html).

I forked [the original repository](https://github.com/digidem/filehub-config) to fit my needs.
Some of these changes are specific to Sony SD card file system (I'm using a Sony A7III).

Here are my changes:
- Logging:
  - Centralize logging in the same file located on the hard disk (instead of local `/tmp` directory)
  - Put the date in the logging filename
  - Include the date on each logging line
  - Add logging on `swap.sh`
- Swap:
  - Increase swap file size
  - Fix the swap creation (add the missing `mkswap`)
- Features:
  - Remove the backup between two USB hard drives as I don't need it and my FileHub only have 1 USB port
  - Remove `MEDIA_REGEX` as I want to avoid removing wrong files by mistake
  - Remove files from SD card when copied (using `--remove-source-files` option of rsync)
  - Backup video as well (`PRIVATE` directory)
- Rename some paths and files


How to hack the Filehub embedded Linux
--------------------------------------

The RAVPower Filehub runs embedded Linux, which is a cut-down version of Linux with a low memory footprint. Most of the filesystem is read-only apart from the contents of `/etc` and `/tmp`, but changes are not persisted across reboots.

The easiest way to "hack" / modify the configuration of the embedded Linux is to create a script `EnterRouterMode.sh` on an SD card and put the card in the Filehub. The current firmware (2.000.004) will execute a script with this name with root permissions when the SD card is mounted.

The `EnterRouterMode.sh` script modifies scripts within `/etc` and persists changes by running `/usr/sbin/etc_tools p`.

To use, download the EnterRouterMode.sh script, copy it to the top-level folder of an SD card, and insert it into the filehub device.

Building from source
--------------------

```shell
git clone https://github.com/m42u/filehub-config
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

The script runs when any USB device is attached. It checks whether an SD card is present, and it looks for an external USB drive (can be a thumb drive or a USB disk drive) with a folder `/filehub/config` which contains an [rsync](http://rsync.samba.org/) binary built for embedded linux. There is not enough memory on the filehub device to store the rsync binary on the device itself.

The script uses rsync to copy files, which should be resilient to interuption mid-copy and resume where it left off. Source files are removed from the SD card as they are copied to the external drive.

A folder is created for each SD card, identified by a [UUID](http://en.wikipedia.org/wiki/Universally_unique_identifier). It would be ideal to use the serial number for an SD card for the UUID, but unfortunately it is not possible to access this. `udevadm info -a -p  $(udevadm info -q path -n /dev/sda) | grep -m 1 "ATTRS{serial}" | cut -d'"' -f2` returns the serial number for the card reader, rather than the SD card. Instead we generate a UUID using `cat /proc/sys/kernel/random/uuid` and store that on the SD card. Bear in mind if an SD card is re-formatted in the camera then this UUID will be lost, so the card will appear as a new card next time it is inserted. Using a UUID allows for transfers to be interupted and resumed later.

If more than 9999 photos are taken with a camera, filenames will be reused. Similarly if an SD card is used in a different camera, filenames will be repeated. This would lead to overwriting files if we just stored all photos from each SD card in a single folder. Instead we create a subfolder for each import. Ideally this would be named with the date of the import, but the clock on the RavPower device cannot be relied upon without internet access. Instead we use the date of the most recent photo on the SD Card as the name of the subfolder.

When the SD card or USB drive is removed, we kill the rsync process, otherwise it hangs around.

Swap file
---------

The RavPower Filehub only has 28Mb of memory, and about 2Mb of free memory. Rsync needs around [100 bytes for each file](http://rsync.samba.org/FAQ.html#4). To avoid out of memory issues we create a 128Mb swapfile on the USB drive when it is connected. This appears to speed up rsync and *should* avoid memory issues. I have not yet tested with thousands of files.

Renaming with EXIF
------------------

I would like photo filenames to be unique, so we can use them as a UUID. The best way would be to read the EXIF capture date, and prepend that to the filename. Although it might be possible to do that with just the file creation date and time. To use EXIF we would need to cross-compile an EXIF utility for the MIPS architecture used in the RavPower.

ODK Collect Imports
-------------------

We are using [ODK Collect](http://opendatakit.org/use/collect/) for data collection. This Android app stores data in a folder on the phone storage, and allows for sending that info via a multi-part form submission. There are 3 options for getting that data onto the filehub:

1. Modify the [form submission code](https://code.google.com/p/opendatakit/source/browse/src/org/odk/collect/android/tasks/InstanceUploaderTask.java?repo=collect) in ODK collect so that instead of a multipart form upload, it uploads the form as an XML file to the WebDav server on the RavPower. The Ravpower can be configured so that the ODK server address will redirect locally when no internet connection is present.

2. Write a small CGI script that can run on the RavPower to accept a multi-part form submission (containing form XML and associated media/photos). It would need to rename the files with the form submission UUID. Could face memory and processing speed limitations.

3. Transfer the data via a USB connection. Android >4.0 only connects via MTP, which varies in implmentation in Android. The best seems to be [go-mtpfs](https://github.com/hanwen/go-mtpfs) which would need to be cross-compiled with GO for MIPS architecture, which seems is possible. All libraries would need to be statically linked. This is potentially the most reliable solution.

TODO
----

- Test with a GoPro SD card and adapt `rsync` commands accordingly
- Test if, when an unexpected interruption occurs during the rsync process (shutdown of the FileHub, SD card or hard disk unplugged), rsync resume and all files are properly copied.
