#!/tmp/busybox sh
#
# Universal Updater Script for Samsung Galaxy S Phones
# (c) 2011 by Teamhacksung
# Galaxy S 4G (SGH-T959V) Edition. -- TeamAcid
#

check_mount() {
    if ! /tmp/busybox grep -q $1 /proc/mounts ; then
        /tmp/busybox mkdir -p $1
        /tmp/busybox umount -l $2
        if ! /tmp/busybox mount -t $3 $2 $1 ; then
            /tmp/busybox echo "Cannot mount $1."
            exit 1
        fi
    fi
}

set_log() {
    rm -rf $1
    exec >> $1 2>&1
}

set -x
export PATH=/:/sbin:/system/xbin:/system/bin:/tmp:$PATH

# check for old/non-cwm recovery.
if ! /tmp/busybox test -n "$UPDATE_PACKAGE" ; then
    # scrape package location from /tmp/recovery.log
    UPDATE_PACKAGE=`/tmp/busybox cat /tmp/recovery.log | /tmp/busybox grep 'Update location:' | /tmp/busybox tail -n 1 | /tmp/busybox cut -d ' ' -f 3-`
fi

# check if we're running on a bml or mtd device
if /tmp/busybox test -e /dev/block/bml7 ; then
    # we're running on a bml device

    # make sure /sdcard is mounted
    check_mount /sdcard /dev/block/mmcblk0p1 vfat

    # everything is logged into /sdcard/cyanogenmod_bml.log
    set_log /sdcard/cyanogenmod_bml.log

    # make sure efs is mounted
    check_mount /efs /dev/block/stl3 rfs

    # create a backup of efs
    if /tmp/busybox test -e /sdcard/backup/efs ; then
        /tmp/busybox mv /sdcard/backup/efs /sdcard/backup/efs-$$
    fi
    /tmp/busybox rm -f /sdcard/backup/efs

    /tmp/busybox mkdir -p /sdcard/backup/efs
    /tmp/busybox cp -R /efs/ /sdcard/backup

    # write the package path to sdcard cyanogenmod.cfg
    if /tmp/busybox test -n "$UPDATE_PACKAGE" ; then
        PACKAGE_LOCATION=${UPDATE_PACKAGE#/mnt}
        /tmp/busybox echo "$PACKAGE_LOCATION" > /sdcard/cyanogenmod.cfg
    fi

    # Scorch any ROM Manager settings to require the user to reflash recovery
    /tmp/busybox rm -f /sdcard/clockworkmod/.settings

    # write new kernel to boot partition
    /tmp/flash_image boot /tmp/boot.img
    if [ "$?" != "0" ] ; then
        exit 3
    fi
    /tmp/busybox sync

    /sbin/reboot now
    exit 0

elif /tmp/busybox test -e /dev/block/mtdblock0 ; then
# we're running on a mtd device

    # make sure sdcard is mounted
    check_mount /sdcard /dev/block/mmcblk0p1 vfat

    # everything is logged into /sdcard/cyanogenmod.log
    set_log /sdcard/cyanogenmod_mtd.log

    # create mountpoint for radio partition
    /tmp/busybox mkdir -p /radio

    # make sure radio partition is mounted
    check_mount /radio /dev/block/mtdblock6 yaffs2

    # if modem.bin doesn't exist on radio partition, format the partition and copy it
    if ! /tmp/busybox test -e /radio/modem.bin ; then
        /tmp/busybox umount -l /dev/block/mtdblock6
        /tmp/erase_image radio
        if ! /tmp/busybox mount -t yaffs2 /dev/block/mtdblock6 /radio ; then
            /tmp/busybox echo "Cannot copy modem.bin to radio partition."
            exit 5
        else
            /tmp/busybox cp /tmp/modem.bin /radio/modem.bin
            /tmp/busybox sync
        fi
    fi

    # unmount radio partition
    /tmp/busybox umount -l /dev/block/mtdblock6

    # flash boot image
    /tmp/erase_image boot
    /tmp/bml_over_mtd.sh boot 72 reservoir 4012 /tmp/boot.img

    # remove the cyanogenmod.cfg to prevent this from looping
    /tmp/busybox rm -f /sdcard/cyanogenmod.cfg

    # unmount system and data (recovery seems to expect system to be unmounted)
    /tmp/busybox umount -l /system
    #/tmp/busybox umount -l /data

    # erase system
    /tmp/erase_image system
    # erase userdata
    #/tmp/erase_image userdata

    # restart into recovery so the user can install further packages before booting
    #/tmp/busybox touch /cache/.startrecovery

    # 
    check_mount /efs /dev/block/mtdblock4 yaffs2
    if ! /tmp/busybox find /efs -name 'nv_data\.bin' ; then
        /tmp/busybox umount -l /efs
        /tmp/erase_image efs
        /tmp/busybox mkdir -p /efs
        
        check_mount /efs /dev/block/mtdblock4 yaffs2

        # newer aries backup
        if /tmp/busybox test -d /sdcard/backup/efs ; then
            /tmp/busybox cp -R /sdcard/backup/efs /
            /tmp/busybox umount -l /efs
        # older herring backup
        elif /tmp/busybox test -e /sdcard/backup/efs.tar ; then
            cd /sdcard/backup
            if /tmp/busybox test -e efs.tar.md5 ; then
                /tmp/busybox md5sum -c efs.tar.md5
                if [ "$?" = "0" ]; then
                    cd /efs
                    /tmp/busybox tar xf /sdcard/backup/efs.tar
                else
                    /tmp/busybox echo "/sdcard/backup/efs.tar MD5 Checksum failed!"
                    exit 7
                fi
           else
               /tmp/busybox echo "/sdcard/backup/efs.tar.md5 not found!"
               exit 8
           fi
        fi
        /tmp/busybox sync
        /tmp/busybox umount -l /efs
    else
        /tmp/busybox echo "Cannot restore efs."
        exit 9
    fi

    exit 0
fi
