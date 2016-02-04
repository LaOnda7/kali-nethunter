#!/sbin/sh
# Prepare a block filesystem for Kali Chroot

TMP=/tmp/nethunter

. $TMP/env.sh

console=$(cat /tmp/console)
[ "$console" ] || console=/proc/$$/fd/1

print() {
	echo "ui_print - $1" > $console
	echo
}

abort() {
	[ "$1" ] && print "Error: $1"
	exit 1
}

mount_block() {
	mount -t ext4 "$KBLOCK" "$KSYS" || {
		abort "Could not mount filesystem!"
	}
}

KBLOCK=/external_sd/kali-$ARCH.ext4
KSIZE=10G
KSYS=/data/local/nhsystem/kali-$ARCH

# Check installer for kalifs archive
KALIFS=$(ls $TMP/kalifs-*.tar.xz)
# If not found, check /data/local instead
[ -f "$KALIFS" ] || KALIFS=$(ls /data/local/kalifs-*.tar.xz)

[ -d "$KSYS" ] && {
	[ -e "$KSYS/"* ] && {
		print "Found existing files in mount directory!"
		# move chroot to .old so it can be moved to the block filesystem later
		mv "$KSYS" "$KSYS.old"
	}
}

mkdir -p "$KSYS"

[ -f "$KBLOCK" ] && {
	print "Mounting previous Kali-$ARCH filesystem..."
	mount_block
} || {
	print "Creating $KSIZE ext4 filesystem for Kali..."
	truncate -s "$KSIZE" "$KBLOCK" && mkfs.ext4 "$KBLOCK" || {
		abort "Could not create ext4 block filesystem!"
	}
	print "Mounting Kali-$ARCH filesystem..."
	mount_block
	# if a new kalifs archive is found, don't move old one
	[ -f "$KALIFS" ] && return
	# otherwise move the old chroot to the new filesystem
	[ -d "$KSYS.old" ] && {
		print "Moving previous chroot to new filesystem"
		print "(this may take a long time...)"
		cp -a "$KSYS.old/." "$KSYS/" && {
			rm -rf "$KSYS.old"
		} || {
			print "Couldn't move previous chroot!"
			rm -rf "$KSYS/*"
		}
	}
}
