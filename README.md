# Droid Native
Next Generation Anbox Style Android x86 Desktop - Anbox, Lineage, WayDroid, BlissOS, Dock-Droid

Based on waydroid's anbox halium for x86 (Desktop & Arch)
# https://github.com/waydroid/anbox-halium/issues/13#issuecomment-896958045

# Requirements

```bash
sudo pacman -Syu lxc dhcp

```

Credits for WayDroid via [https://github.com/waydroid/anbox-halium](https://github.com/waydroid/anbox-halium) [https://github.com/erfanoabdi](@erfanoabdi)!

Credits for native_bridge install via Redroid [https://github.com/zhouziyang](@zhouziyang)!

[https://github.com/remote-android/redroid-doc/tree/master/native_bridge](https://github.com/remote-android/redroid-doc/tree/master/native_bridge)


# Wipe existing WayDroid/Lineage/Bliss Data # Droid-Native

```bash

#!/bin/bash
# Author:       atmouse-, sickcodes
# Contact:      https://github.com/atmouse-, https://github.com/sickcodes
# Copyright:    sickcodes (C) 2021
# License:      GPLv3+


HEIGHT=1440
WIDTH=810
# HEIGHT=720
# WIDTH=405
WAYLAND_DISPLAY=wayland-1
# BRIDGE=anbox0
BRIDGE=lxcbr0
DATA_FOLDER=/var/lib/lxc/anbox/data
IMAGE_ZIP_URL="https://build.lolinet.com/file/lineage/anbox_x86_64/latest-raw-images.zip"
# IMAGE_ZIP_URL="${IMAGE_ZIP_URL:="file:///home/${USER}/images.zip"}"
DOWNLOAD=
# DOWNLOAD=true
# WIPE_EXISTING=
WIPE_EXISTING=/var/lib/lxc/anbox/data

if [[ "${WIPE_EXISTING}" ]]; then
    sudo rm -rf /var/lib/lxc/anbox/data
fi

# zip up your system and vendor raw images, or use lineage latest

# stat /var/lib/lxc || { echo "lxc is not installed" ; exit 1} 

sudo mkdir -p /var/lib/lxc/anbox/rootfs \
    /var/lib/lxc/anbox/data

sudo touch /var/lib/lxc/anbox/anbox.prop \
    /var/lib/lxc/anbox/bootstrap.sh \
    /var/lib/lxc/anbox/config \
    /etc/dhcpd.anbox.conf

sudo tee /var/lib/lxc/anbox/anbox.prop <<EOF
anbox.display_height=${HEIGHT}
anbox.display_width=${WIDTH}
ro.hardware.gralloc=gbm
ro.hardware.egl=mesa
debug.stagefright.ccodec=0
ro.sf.lcd_density=160
anbox.xdg_runtime_dir=/run/user/1000
anbox.wayland_display=${WAYLAND_DISPLAY}
anbox.stub_sensors_hal=1
#anbox.use_subsurface=false
persist.anbox.multi_windows=false
anbox.active_apps=full

#ndk
ro.dalvik.vm.native.bridge=libndk_translation.so
ro.product.cpu.abilist=x86_64,arm64-v8a,x86,armeabi-v7a,armeabi
ro.product.cpu.abilist32=x86,armeabi-v7a,armeabi
ro.ndk_translation.version=0.2.2
EOF


sudo tee /var/lib/lxc/anbox/nativebridge.rc <<EOF
on early-init
    setprop gralloc.gbm.device /dev/dri/renderD128
    setprop ro.product.cpu.abilist x86_64,arm64-v8a,x86,armeabi-v7a,armeabi
    setprop ro.product.cpu.abilist64 x86_64,arm64-v8a
    setprop ro.product.cpu.abilist32 x86,armeabi-v7a,armeabi
    setprop ro.dalvik.vm.isa.arm x86
    setprop ro.dalvik.vm.isa.arm64 x86_64
    setprop ro.enable.native.bridge.exec 1
    setprop ro.dalvik.vm.native.bridge libndk_translation.so
    setprop ro.ndk_translation.version 0.2.2
EOF


# far too permissive

sudo tee /var/lib/lxc/anbox/bootstrap.sh <<EOF
#!/bin/sh
export XDG_RUNTIME_DIR=/run/user/1000
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY}
chmod 777 /sys/kernel/debug/sync/sw_sync
chmod 777 -R /run/user/1000 || true
chmod -R 777 /dev/binderfs/*
chmod -R 777 /dev/fb0
chmod -R 777 /dev/dri/
chmod -R 777 /dev/uhid
chmod -R 777 /dev/zero
chmod -R 777 /dev/full
chmod -R 777 /dev/null
chmod -R 777 /dev/ashmem
chmod -R 777 /dev/fuse
chmod -R 777 /dev/char
EOF

sudo tee /var/lib/lxc/anbox/config <<EOF
# Anbox LXC Config

lxc.rootfs.path = dir:/var/lib/lxc/anbox/rootfs
lxc.uts.name = anbox
lxc.arch = x86_64
lxc.autodev = 0
lxc.apparmor.profile = unconfined

lxc.init.cmd = /init

lxc.mount.auto = cgroup:rw sys:ro proc

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.link = ${BRIDGE}
lxc.net.0.name = eth0
lxc.net.0.hwaddr = 00:16:3e:f9:d3:03
lxc.net.0.mtu = 1500

# Necessary dev nodes
lxc.mount.entry = tmpfs dev tmpfs nosuid 0 0
lxc.mount.entry = /dev/zero dev/zero none bind,create=file,optional 0 0
lxc.mount.entry = /dev/full dev/full none bind,create=file,optional 0 0
lxc.mount.entry = /dev/null dev/null none bind,create=file,optional 0 0
lxc.mount.entry = /dev/ashmem dev/ashmem none bind,create=file,optional 0 0
lxc.mount.entry = /dev/fuse dev/fuse none bind,create=file,optional 0 0

####lxc.mount.entry = /dev/ion dev/ion none bind,create=file,optional 0 0
lxc.mount.entry = /dev/char dev/char none bind,create=dir,optional 0 0

##### Graphic dev nodes
lxc.mount.entry = /dev/fb0 dev/fb0 none bind,create=file,optional 0 0
lxc.mount.entry = /dev/dri dev/dri none bind,create=dir,optional 0 0

##### Binder dev nodes
lxc.mount.entry = /dev/binderfs/anbox-binder dev/binder none bind,create=file 0 0
lxc.mount.entry = /dev/binderfs/anbox-vndbinder dev/vndbinder none bind,create=file 0 0
lxc.mount.entry = /dev/binderfs/anbox-hwbinder dev/hwbinder none bind,create=file 0 0

# Necessary device nodes for adb
lxc.mount.entry = none dev/pts devpts defaults,mode=644,ptmxmode=666,create=dir 0 0
lxc.mount.entry = /dev/uhid dev/uhid none bind,create=file,defaults,optional 0 0

# Mount /data
lxc.mount.entry = tmpfs mnt tmpfs mode=0755,uid=0,gid=1000
lxc.mount.entry = ${DATA_FOLDER} data none bind 0 0

# Recursive mount /run to provide necessary host sockets
lxc.mount.entry = /run run none rbind,create=dir 0 0

# Necessary sw_sync node for HWC
lxc.mount.entry = /sys/kernel/debug sys/kernel/debug none rbind,create=dir,optional 0 0

lxc.hook.post-stop = /dev/null
EOF

# sudo tee /etc/dhcpd.anbox.conf <<EOF
# option domain-name-servers 8.8.8.8;
# option subnet-mask 255.255.255.0;
# option routers 192.168.250.1;
# subnet 192.168.250.0 netmask 255.255.255.0 {
#     range 192.168.250.150 192.168.250.250;
# }
# EOF

sudo chmod +x /var/lib/lxc/anbox/bootstrap.sh

cd /var/lib/lxc/anbox

if [[ "${DOWNLOAD}" ]]; then
    DOWNLOAD_FILE_NAME="$(basename "${IMAGE_ZIP_URL}")"
    sudo wget -O "${DOWNLOAD_FILE_NAME}" "${IMAGE_ZIP_URL}"
    sudo unzip ${DOWNLOAD_FILE_NAME}
fi
```

### Run script

Run the Android image natively:

```bash
wayfire &
sudo mount -o rw    /var/lib/lxc/anbox/anbox_x86_64_system.img  /var/lib/lxc/anbox/rootfs
sudo mount -o rw    /var/lib/lxc/anbox/anbox_x86_64_vendor.img  /var/lib/lxc/anbox/rootfs/vendor
sudo mount -o bind  /var/lib/lxc/anbox/anbox.prop               /var/lib/lxc/anbox/rootfs/vendor/anbox.prop

# warning, this will extract overwriting /etc/system/... so make sure you're in /tmp
cd /var/lib/lxc/anbox \
    && sudo wget https://github.com/sickcodes/dock-droid/raw/master/native-bridge.tar.gz \
    && sudo tar -xzvf native-bridge.tar.gz \
    && sudo cp /var/lib/lxc/anbox/nativebridge.rc /var/lib/lxc/anbox/rootfs/vendor/etc/init/nativebridge.rc


export DISPLAY=:1
sudo bash /var/lib/lxc/anbox/bootstrap.sh
# sudo ip link add name ${BRIDGE} type bridge
sudo ip link set dev ${BRIDGE} up
# sudo dhcpd -4 -q -cf /etc/dhcpd.anbox.conf --no-pid anbox0
sudo lxc-start -n anbox -F -- /init

```

If `DISPLAY=:1` does not work, open a terminal in wayfire and `echo ${DISPLAY}` and edit as appropriate.


### Stop or Destory Container

```bash
# umount the devices in this important order
sudo umount /var/lib/lxc/anbox/rootfs/vendor/anbox.prop
sudo umount /var/lib/lxc/anbox/rootfs/vendor
sudo umount /var/lib/lxc/anbox/rootfs

sudo lxc-destroy anbox

```