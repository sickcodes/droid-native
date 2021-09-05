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


# Arch Linux Install Bleeding Edge Kernel


```bash
KERNEL_MAINLINE="$(curl https://www.kernel.org \
        | grep -Po '(?<=https\:\/\/git\.kernel\.org\/torvalds\/t\/linux\-)(.+?)(?=\.tar\.gz)')"

RC="${KERNEL_MAINLINE//\-/}"
cd ~
sudo pacman -Rns linux-git --noconfirm
yay linux-git --getpkgbuild --force
cd ~/linux-git


# remove html docs
sed -i -e 's/\"\$pkgbase-docs\"//' PKGBUILD
sed -i -e 's/rm\ -r\ \"\$builddir\/Documentation\"//' PKGBUILD
sed -i -e 's/make\ htmldocs//' PKGBUILD
# sed -i -e 's/make\ /make\ -j'${N}'\ /g' PKGBUILD
sed -i -e 's/^pkgver\=.*/pkgver\='${RC}'/' PKGBUILD
sed -i -e 's/^pkgver\=.*/pkgver\='${RC}'/' PKGBUILD

# MANUALLY EDIT OUT THE SKIP SHASUMS TO SKIP

sed -i -e s/^sha256sums/old_sha256sums/g PKGBUILD

perl -i -p -e s/old_sha256sums/sha256sums\=\(\'SKIP\'\ \'SKIP\'\)\\nold_sha256sums/g PKGBUILD

zcat /proc/config.gz  > config

tee -a config <<EOF
CONFIG_ASHMEM=y
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDERFS=y
CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
CONFIG_SW_SYNC=y
CONFIG_UHID=m
EOF

makepkg -si --noconfirm

```

Add to `/boot/syslinux` or boot with kernel arguments:

`binder.devices=binder,hwbinder,vndbinder,anbox-binder,anbox-hwbinder,anbox-vndbinder`

# Wipe existing WayDroid/Lineage/Bliss Data # Droid-Native

```bash

#!/bin/bash
# Author:       atmouse-, sickcodes
# Contact:      https://github.com/atmouse-, https://github.com/sickcodes
# Copyright:    sickcodes (C) 2021
# License:      GPLv3+

sudo systemctl enable --now systemd-networkd.service
sudo systemctl restart lxc lxc-net lxcfs lxc-auto

sudo su

HEIGHT=720
WIDTH=405
# HEIGHT=1440
# WIDTH=810
# HEIGHT=720
# WIDTH=1280

WAYLAND_DISPLAY=wayland-1
# BRIDGE=anbox0
BRIDGE=lxcbr0
DATA_FOLDER=/var/lib/lxc/anbox/data
IMAGE_ZIP_URL="https://build.lolinet.com/file/lineage/anbox_x86_64/latest-raw-images.zip"
# IMAGE_ZIP_URL="${IMAGE_ZIP_URL:="file:///home/${USER}/images.zip"}"
DOWNLOAD=true
# DOWNLOAD=
# WIPE_EXISTING=
# WIPE_EXISTING=/var/lib/lxc/anbox/data

# if [[ "${WIPE_EXISTING}" ]]; then
#     sudo rm -rf /var/lib/lxc/anbox/data
# fi

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
anbox.wayland_display=wayland-1
anbox.stub_sensors_hal=1
#anbox.use_subsurface=false
persist.anbox.multi_windows=false
anbox.active_apps=full
EOF


    # setprop gralloc.gbm.device /dev/dri/renderD128
sudo tee /var/lib/lxc/anbox/nativebridge.rc <<EOF
on early-init
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
sudo modprobe binder
sudo modprobe ashmem
export XDG_RUNTIME_DIR=/run/user/1000
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=wayland-1
chmod 777 /sys/kernel/debug/sync/sw_sync
chmod 777 -R /run/user/1000
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
sudo mkdir /dev/binderfs
sudo mount -t binder binder /dev/binderfs

# warning, this will extract overwriting /etc/system/... so make sure you're in /tmp
cd /var/lib/lxc/anbox/rootfs \
    && sudo wget https://github.com/sickcodes/dock-droid/raw/master/native-bridge.tar.gz \
    && sudo tar -xzvf native-bridge.tar.gz \
    && sudo rm native-bridge.tar.gz \
    && sudo cp /var/lib/lxc/anbox/nativebridge.rc /var/lib/lxc/anbox/rootfs/vendor/etc/init/nativebridge.rc \
    && sudo rm /var/lib/lxc/anbox/nativebridge.rc \
    && cd ..
```

# libndk native bridge installation lineageos waydroid anbox halium

```bash
sudo sed -i -e 's/native.bridge=0/native.bridge=1/' /var/lib/lxc/anbox/rootfs/system/etc/prop.default

sudo sed -i -e "s/x86_64,x86/x86_64,arm64-v8a,x86,armeabi-v7a,armeabi/g" \
    /var/lib/lxc/anbox/rootfs/system/build.prop \
    /var/lib/lxc/anbox/rootfs/vendor/odm/etc/build.prop \
    /var/lib/lxc/anbox/rootfs/vendor/build.prop

# sudo system/etc/prop.default

sudo tee -a /var/lib/lxc/anbox/rootfs/system/build.prop \
    -a /var/lib/lxc/anbox/rootfs/vendor/odm/etc/build.prop \
    -a /var/lib/lxc/anbox/rootfs/vendor/build.prop <<EOF
ro.product.cpu.abilist64=x86_64,arm64-v8a
ro.product.cpu.abilist32=x86,armeabi-v7a,armeabi
ro.dalvik.vm.isa.arm=x86
ro.dalvik.vm.isa.arm64=x86_64
ro.enable.native.bridge.exec=1
ro.dalvik.vm.native.bridge=libndk_translation.so
EOF
```

# Opengapps installation lineageos waydroid anbox halium

Do not run, work in progress

```bash
# # gapps installation code via Maintainer: Jack Chen <redchenjs@live.com>
# # Based on https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=anbox-image-gapps-rooted

# _gapps_list=(
#   'gsfcore-all'
#   'gsflogin-all'
#   'gmscore-x86_64'
#   'vending-x86_64'
# )

# ANDROID_VERSION=11.0
# GAPPS_VARIANT=nano
# GAPPS_RELEASE="$(curl -s -L https://api.opengapps.org/list | sed -r "s/.*-x86_64-${ANDROID_VERSION}-${GAPPS_VARIANT}-([0-9]+).zip\".*/\1/")"

# mkdir -p /tmp/opengapps
# cd /tmp/opengapps
# wget https://downloads.sourceforge.net/project/opengapps/x86_64/${GAPPS_RELEASE}/open_gapps-x86_64-${ANDROID_VERSION}-${GAPPS_VARIANT}-${GAPPS_RELEASE}.zip
# unzip open_gapps-x86_64-${ANDROID_VERSION}-${GAPPS_VARIANT}-${GAPPS_RELEASE}.zip



# tar --lzip -xvf /tmp/opengapps/Core/*.tar.lz


#       # install media codecs
# cp media_codec*.xml /var/lib/lxc/anbox/rootfs/system/etc/
# cd /tmp/opengapps/Core/
# for i in /tmp/opengapps/Core/*; do
#     tar --lzip -xvf "${i}"
#     sudo cp -r "${i//\.tar\.lz/}/nodpi/priv-app/"* /var/lib/lxc/anbox/rootfs/system/priv-app/
# done

```


# Root Android x86

Do not run, work in progress

```bash

# cd /tmp
# wget https://supersuroot.org/downloads/SuperSU-v2.82-201705271822.zip
#     unzip SuperSU-v2.82-201705271822.zip

# sudo su <<EOF
# mkdir -p /var/lib/lxc/anbox/rootfs/system/app/SuperSU
# chmod 755 /var/lib/lxc/anbox/rootfs/system/app/SuperSU
# install -Dm 644 /tmp/common/Superuser.apk /var/lib/lxc/anbox/rootfs/system/app/SuperSU/Superuser.apk

# rm /var/lib/lxc/anbox/rootfs/system/bin/app_process
# ln -s /system/xbin/daemonsu /var/lib/lxc/anbox/rootfs/system/bin/app_process
# mv /var/lib/lxc/anbox/rootfs/system/bin/app_process64 /var/lib/lxc/anbox/rootfs/system/bin/app_process64_original
# ln -s /system/xbin/daemonsu /var/lib/lxc/anbox/rootfs/system/bin/app_process64
# cp /var/lib/lxc/anbox/rootfs/system/bin/app_process64_original /var/lib/lxc/anbox/rootfs/system/bin/app_process_init
# EOF

# nohup /system/xbin/daemonsu --auto-daemon &

# # chmod +w ./system/etc/init.goldfish.sh
# # echo '/system/xbin/daemonsu --auto-daemon &' >> ./system/etc/init.goldfish.sh
# # chmod -w ./system/etc/init.goldfish.sh
# # echo 1 > ./system/etc/.installed_su_daemon

# # # install media codecs
# # cp media_codec*.xml ./system/etc/


####??

# cd /var/lib/lxc/anbox/rootfs \
#     && sudo wget https://mirrorbits.lineageos.org/su/addonsu-14.1-x86-signed.zip \
#     && sudo unzip addonsu-14.1-x86-signed.zip \
#     && sudo rm addonsu-14.1-x86-signed.zip \
#     && cd -
```


```bash
dhcpd -4 -q -cf /etc/dhcpd.anbox.conf --no-pid anbox0

export DISPLAY=:1
cd /var/lib/lxc/anbox
sudo bash /var/lib/lxc/anbox/bootstrap.sh
ip link add name anbox0 type bridge
ip link set dev anbox0 up
# sudo ip link add name ${BRIDGE} type bridge
sudo ip link set dev ${BRIDGE} up
# sudo dhcpd -4 -q -cf /etc/dhcpd.anbox.conf --no-pid anbox0
sudo lxc-start -n anbox -F -- /init
```

```bash

tee -a ~/start-waydroid.sh <<EOF
#!/bin/bash
sudo mkdir -p /dev/binderfs
sudo mount -t binder binder /dev/binderfs
sudo systemctl enable --now systemd-networkd.service
sudo systemctl restart lxc lxc-net lxcfs lxc-auto
sudo bash /var/lib/lxc/anbox/bootstrap.sh
sudo ip link add name anbox0 type bridge
sudo ip link set dev anbox0 up
sudo dhcpd -4 -q -cf /etc/dhcpd.anbox.conf --no-pid anbox0
sudo DISPLAY=:1 lxc-start -n anbox -F -- /init
EOF

sudo DISPLAY=:1 bash ~/start-waydroid.sh

```

`sudo DISPLAY=:1 bash ~/start-waydroid.sh`


If `DISPLAY=:1` does not work, open a terminal in wayfire and `echo ${DISPLAY}` and edit as appropriate.


### Stop or Destory Container anbox container after use

```bash
# umount the devices in this important order
sudo umount /var/lib/lxc/anbox/rootfs/vendor/anbox.prop
sudo umount /var/lib/lxc/anbox/rootfs/vendor
sudo umount /var/lib/lxc/anbox/rootfs
sudo lxc-destroy anbox

```