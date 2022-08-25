---
title: "New Gentoo"
date: 2022-08-23T15:09:04+03:00
draft: true
tags: ["linux"]
---

## Intro
As the summer is coming to a close and before the exam period starts I decided to reinstall gentoo on my university laptop.
I don't plan on doing an ordinary follow the handbook and whabam you're up and running thing so I wanted to document it.

## Background
The laptop I use for university has pretty lackluster specs which is to be expected considering I bought it for 180 euros about 5 years ago.
Nevertheless, it does its job very well and I wouldn't be surprised if I've written more code on it than I have written on my desktop at home.
However I have a habit of putting different distros on it, sometimes wiping it even in the middle of a semester.
It's pretty critical since it is used for a few classes and because I tend to work on personal projects fairly often while at university but that doesn't mean it gets the white glove treatment.

But enough about the laptop, we're here to talk about gentoo.
Generally I can get by on any distro but I'm not going to settle for less than I can have if I can swing it.
There are several trends in the linux world that I dislike and the only distro that allows me to avoid most if not all of them is gentoo.
At the time of writing I've been using it for over 4 years with no plans in the forseeable future to move to something else.
While I do love it, not everything is perfect so we'll need to add at least one overlay and maybe write an ebuild or two but I'm getting ahead of myself.
What's the plan?

## Plan
There are a few main requirements that I'd like the system to meet (in no particular order):
- no systemd
- no udev or eudev
- no logind or elogind
- no consolekit
- no usrmerge
- no dbus
- no pam
- no polkit
- no networkmanager
- no pulseaudio
- no multilib
- no wayland
- no lvm
- no btrfs
- no swap partition
- no grub
- no silly network interface naming
- least amount of packages written in perl, lua, ruby and python
- no packages in unnecessary programming languages (fortran, ocaml, haskell, racket and a few others that some packages pull in)

and probably some that I forget.
It might not be possible to achieve all of them but I want to get as close as possible.
There are also a couple things not on the list that I'd like to have eventually but won't be doing this time, namely using ZFS instead of XFS and having a stripped down kernel.
One might think that not installing certain software would be as easy as just not adding them, and I really wish it was.
However as you'll see later on some packages have hard (meaning non-optional) dependencies on some of the above even where it isn't necessary which complicates things.
With the plan laid out, let's begin.

### Installation media
I headed over to [the gentoo downloads page](https://www.gentoo.org/downloads/), picked up the latest (at the time of writing) minimal installation ISO, which is `install-amd64-minimal-20220821T170533Z.iso`, and used `dd` to write it to a 4gb usb stick
After booting into it in cached mode (this copies the contents of the ISO to RAM) I selected the default keyboard layout, set a root password with `passwd`, started the SSH service with `rc-service sshd start` and looked up the IP address using `ip a`.
From my desktop I opened an SSH session `ssh root@10.0.20.49` and started up `tmux` to make sure that even if I disconnected things would still keep running on the laptop and I could come back to it.

### Partitioning and formatting the drive
When following the handbook, the first step after getting the network up is to [partition our disk](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks).
In my case this is a cheap 240gb SSD I added to the laptop since the 32gb of on-board eMMC was not enough.
There will be just two partitions, one that will be the boot and ESP and one that will be root.
The handbook recommends making the boot partition 256MB but I don't want to fill it up quickly if I'm experimenting with kernel configuration so I'll make it 512MB.
The root partition will take up the rest of the space on the SSD.
When I reinstall with ZFS as the root filesystem I'll probably put the boot/ESP partition on the eMMC so I can manage the entire SSD using only ZFS.
However right now I'll just format the boot one as fat32 and for root I'll go with XFS.
Next up we mount just the root partition at `/mnt/gentoo`, go into it and we're ready to grab our stage3 tarball.

### Stage3
Heading back to the [downloads page](https://www.gentoo.org/downloads/) I decided to go for the no multilib openrc tarball `stage3-amd64-nomultilib-openrc-20220821T170533Z.tar.xz` which is the latest one at the time of writing.
I'm used to `curl` instead of `wget` so a little `curl -O` incantation later and the stage3 is ready to be unpacked with `tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner`.

### Minor configuration
I'm not going to do *too* much configuration before the system is independently bootable but we'll take care of some basics.
Sadly the installation media doesn't have `vim`, only `vi` but I can make do.

#### `make.conf`

##### MAKEOPTS
First, I added `MAKEOPTS="-j2"` to better take advantage of the processing power.

##### USE
The big one, right.
Initially I'll just set the basics:
```
USE="-systemd -udev -logind -consolekit -policykit -dbus -pam -networkmanager -pulseaudio -wayland -lvm -btrfs -perl -lua -ruby -python -fortran -ocaml -haskell -racket"
````

#### `repos.conf`
Git syncing is generally faster and doesn't seem to have a per-day sync limit so I want to use that over rsync however the stage3 doesn't include `git` so we leave those options commented out for now.

```
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/db/repos/gentoo
#sync-type = git
sync-type = rsync
#sync-uri = https://anongit.gentoo.org/git/repo/sync/gentoo.git
sync-uri = rsync://rsync.gentoo.org/gentoo-portage
auto-sync = yes
sync-rsync-verify-jobs = 1
sync-rsync-verify-metamanifest = yes
sync-rsync-verify-max-age = 24
sync-openpgp-key-path = /usr/share/openpgp-keys/gentoo-release.asc
sync-openpgp-keyserver = hkps://keys.gentoo.org
sync-openpgp-key-refresh-retry-count = 40
sync-openpgp-key-refresh-retry-overall-timeout = 1200
sync-openpgp-key-refresh-retry-delay-exp-base = 2
sync-openpgp-key-refresh-retry-delay-max = 60
sync-openpgp-key-refresh-retry-delay-mult = 4
sync-webrsync-verify-signature = yes
```

#### Pseudo-filesystem copy-pasta
Plopping this here for the future

```
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run 
```

And that about does it for the pre-chroot stuff.

### Chroot
Now we change root into what is going to be our system, mount our boot partition and run the initial sync using `emerge-webrsync`.
Next up `git` gets installed so  we can switch to git syncing in the `repos.conf` file mentioned previously.

#### Tangent: (neo)vi(m)
I wanted to edit the root user's `.bash_profile` to automatically include `/etc/profile` and change the prompt and very quickly found out that there isn't even `vi` inside the stage3.
There is the option to install it but I vaguely remember it pulling in some perl or ruby dependencies that I would rather avoid.
Good opportunity to see if `neovim` does better in this regard.
Here is a pretend emerge with USE flags I would set:

```
USE="X -perl" emerge -pv vim

These are the packages that would be merged, in order:

Calculating dependencies... done!
[ebuild  N     ] app-crypt/libmd-1.0.4::gentoo  259 KiB
[ebuild  N     ] x11-base/xorg-proto-2022.1::gentoo  USE="-test" 1082 KiB
[ebuild  N     ] dev-libs/libbsd-0.11.6::gentoo  USE="-static-libs -verify-sig" 407 KiB
[ebuild  N     ] app-eselect/eselect-vi-1.2::gentoo  3 KiB
[ebuild  N     ] dev-libs/libsodium-1.0.18_p20210617:0/23::gentoo  USE="asm urandom -minimal -static-libs -verify-sig" CPU_FLAGS_X86="-aes -sse4_1" 1812 KiB
[ebuild  N     ] x11-libs/xtrans-1.4.0::gentoo  USE="-doc" 182 KiB
[ebuild  N     ] x11-libs/libXau-1.0.9-r1::gentoo  USE="-doc" 316 KiB
[ebuild  N     ] x11-libs/libXdmcp-1.1.3-r1::gentoo  USE="-doc" 325 KiB
[ebuild  N     ] x11-base/xcb-proto-1.15.2::gentoo  PYTHON_TARGETS="python3_10 -python3_8 -python3_9 (-python3_11)" 145 KiB
[ebuild  N     ] x11-libs/libICE-1.0.10-r1::gentoo  USE="ipv6" 384 KiB
[ebuild  N     ] x11-libs/libxcb-1.15-r1:0/1.12::gentoo  USE="xkb -doc (-selinux) -test" 437 KiB
[ebuild  N     ] x11-libs/libSM-1.2.3-r1::gentoo  USE="ipv6 uuid -doc" 355 KiB
[ebuild  N     ] x11-misc/compose-tables-1.8.1::gentoo  1776 KiB
[ebuild  N     ] x11-libs/libX11-1.8.1::gentoo  USE="-doc -test" 0 KiB
[ebuild  N     ] x11-libs/libXt-1.2.1::gentoo  USE="-doc -test" 767 KiB
[ebuild  N     ] app-editors/vim-core-9.0.0099::gentoo  USE="acl nls -minimal" 16324 KiB
[ebuild  N     ] app-editors/vim-9.0.0099::gentoo  USE="X acl crypt nls -cscope -debug -gpm -lua -minimal -perl -python -racket -ruby (-selinux) -sound -tcl -terminal -vim-pager" LUA_SINGLE_TARGET="lua5-1 -lua5-3 -lua5-4 -luajit" PYTHON_SINGLE_TARGET="python3_10 -python3_8 -python3_9 (-python3_11)" 16321 KiB
[ebuild  N     ] app-vim/gentoo-syntax-2::gentoo  USE="-ignore-glep31" 20 KiB

Total: 18 packages (18 new), Size of downloads: 40906 KiB
```

Not too bad, let's see if neovim can do better:

```
USE="-tui -nvimpager" emerge -pv neovim

These are the packages that would be merged, in order:

Calculating dependencies... done!
[ebuild  N     ] dev-lang/luajit-2.1.0_beta3_p20220127-r2:2/2.1.0_beta3_p20220127::gentoo  USE="-lua52compat -static-libs" 1048 KiB
[ebuild  N     ] dev-libs/tree-sitter-0.20.6::gentoo  2857 KiB
[ebuild  N     ] app-eselect/eselect-vi-1.2::gentoo  3 KiB
[ebuild  N     ] app-crypt/rhash-1.4.2::gentoo  USE="nls ssl -debug -static-libs" 408 KiB
[ebuild  N     ] dev-libs/jsoncpp-1.9.5:0/25::gentoo  USE="-doc -test" 211 KiB
[ebuild  N     ] dev-libs/libmpack-1.0.5-r3::gentoo  33 KiB
[ebuild  N     ] app-eselect/eselect-lua-4-r1::gentoo  0 KiB
[ebuild  N     ] dev-libs/libuv-1.44.1:0/1::gentoo  1272 KiB
[ebuild  N     ] dev-lang/lua-5.1.5-r106:5.1::gentoo  USE="deprecated readline" 217 KiB
[ebuild  N     ] dev-libs/libvterm-0.1.4::gentoo  68 KiB
[ebuild  N     ] app-arch/libarchive-3.6.1:0/13::gentoo  USE="acl bzip2 e2fsprogs iconv lzma xattr -blake2 -expat -lz4 -lzo -nettle -static-libs -verify-sig -zstd" 7258 KiB
[ebuild  N     ] dev-util/cmake-3.22.4::gentoo  USE="ncurses -doc -emacs -qt5 -test" 9553 KiB
[ebuild  N     ] dev-lua/lpeg-1.0.2-r101::gentoo  USE="-debug -doc -test" LUA_TARGETS="lua5-1 luajit -lua5-3 -lua5-4" 71 KiB
[ebuild  N     ] dev-lua/mpack-1.0.9-r1::gentoo  USE="-test" LUA_TARGETS="lua5-1 luajit -lua5-3 -lua5-4" 16 KiB
[ebuild  N     ] dev-lua/luv-1.43.0.0::gentoo  USE="-test" LUA_SINGLE_TARGET="luajit -lua5-1 -lua5-3 -lua5-4" 172 KiB
[ebuild  N     ] dev-libs/msgpack-3.3.0:0/2::gentoo  USE="cxx -boost -doc -examples -static-libs -test" 497 KiB
[ebuild  N     ] app-editors/neovim-0.7.2::gentoo  USE="lto -nvimpager -test -tui" LUA_SINGLE_TARGET="luajit -lua5-1" 10678 KiB

Total: 17 packages (17 new), Size of downloads: 34352 KiB
```

That's too much lua so we're going with `vim` instead but it was worth checking out.
A little `echo 'app-editors/vim X -lua -perl -python -racket -ruby -terminal -vim-pager' > /etc/portage/package.use/vim` later and we're set.

#### First encounter with udev
After syncing, I saw the `eselect news read` prompt and decided to take a look.
I remembered that unfortunately the default now is to use systemd udev instead of eudev so I was planning on masking `sys-fs/udev` but thanks to reading the latest news I know I need to mask `sys-apps/systemd-utils` instead.
The road is getting rocky already but we'll move forward regardless.
Being a fan of the `s6` suite of software and `mdevd` being a device manager by the same author I thought I'd go with that but it's not available in the main repository.
No worries, `mdev` provided by busybox can work too.

The guide I followed for this part is the excellent [gentoo wiki article about mdev](https://wiki.gentoo.org/wiki/Mdev).
Armed with some `echo 'sys-apps/busybox mdev static' > /etc/portage/package.use/busybox` we have a device manager.
To be honest I forgot about `static` initially so I ran `emerge -avuDN @world` so the USE changes would be in effect but without the correct flags for busybox.
After I noticed I was missing the `static` flag, I added it and re-updated.
Such is life sometimes.
Running `emerge -avc` removed most of the undesireables but `sys-apps/systemd-utils` persisted.
When trying to see what was keeping it here this is what I got:

```
emerge -avc systemd-utils

Calculating dependencies... done!
  sys-apps/systemd-utils-250.7 pulled in by:
    virtual/tmpfiles-0-r3 requires sys-apps/systemd-utils[tmpfiles]


emerge -avc virtual/tmpfiles

Calculating dependencies... done!
  virtual/tmpfiles-0-r3 pulled in by:
    sys-apps/man-db-2.10.2-r1 requires virtual/tmpfiles, =virtual/tmpfiles-0-r3
    sys-apps/openrc-0.44.10 requires virtual/tmpfiles, =virtual/tmpfiles-0-r3
```

So it seems like man and openrc depend on it which is unfortunate but they at least depend on a `virtual` package so that if a systemd-free options exists we can use that instead.
I could get rid of man, it's not crucial, but that gets me nowhere since openrc also depends on tmpfiles.
There is an alternative implementation that used to be the default by gentoo called [opentmpfiles](https://github.com/OpenRC/opentmpfiles) that isn't active anymore but should work and is [packaged by funtoo](https://github.com/funtoo-testing/kit-fixups/tree/81fd81bea6861ead3df21e664200027ddac9ad4d/core-kit/curated/sys-apps/opentmpfiles) so there is an ebuild for it already.
Writing a modified `virtual/tmpfiles` ebuild to include this is a TODO for later.
There is also [an implementation in rust](https://github.com/rust-torino/tmpfiles-rs).
At any rate I seem to have gotten rid of udev which is a pretty big deal.
To make sure we're alerted in case something tries to reinstall it, let's mask it.
I made a file `/etc/portage/package.mask/udev` with the following contents:

```
virtual/udev
sys-fs/udev
sys-fs/eudev
sys-fs/udev-init-scripts
virtual/libudev
dev-libs/libgudev
dev-python/pyudev
```

#### Continuing with the chroot
Now that that's handled, where was I?
In the new system, right.
Setting the timezone and locale and... oh right!
I forgot to mask the packages earlier.

#### Masking undesired software
After setting the timezone and locale I remembered that I only masked udev.
We need to mask systemd, dbus, polkit, pam, networkmanager, pulseaudio, lvm, btrfs and wayland.

First up `/etc/portage/package.mask/systemd`:
```
app-admin/systemdgenie
dev-ml/systemd
dev-python/python-systemd
sys-apps/gentoo-systemd-integration
sys-apps/systemd
sys-apps/systemd-bootchart
sys-apps/systemd-readahead
sys-apps/systemd-tmpfiles
#sys-apps/systemd-utils #masked. for now...
sys-boot/systemd-boot
sys-kernel/installkernel-systemd-boot
sys-process/systemd-cron
```

Next up, `/etc/portage/package.mask/dbus`:
```
dev-cpp/sdbus-c++
dev-dotnet/ndesk-dbus
dev-dotnet/ndesk-dbus-glib
dev-haskell/dbus
dev-libs/dbus-c++
dev-libs/dbus-glib
dev-libs/libdbusmenu
dev-libs/libdbusmenu-qt
dev-libs/libmodbus
dev-perl/Net-DBus
dev-python/dbus-next
dev-python/dbus-python
dev-python/pydbus
dev-python/python-dbus-next
dev-python/python-dbusmock
dev-qt/qdbus
dev-qt/qdbusviewer
dev-qt/qtdbus
dev-util/dbus-test-runner
dev-util/gdbus-codegen
gnustep-libs/dbuskit
kde-frameworks/kdbusaddons
net-im/skype-dbus-mock
net-libs/dleyna-connector-dbus
sec-policy/selinux-dbus
sys-apps/dbus
sys-apps/dbus-broker
sys-apps/xdg-dbus-proxy
```

Moving on to `/etc/portage/package.mask/polkit`:
```
gnome-extra/polkit-gnome
kde-plasma/polkit-kde-agent
mate-extra/mate-polkit
sys-auth/polkit
sys-auth/polkit-pkla-compat
sys-auth/polkit-qt
lxqt-base/lxqt-policykit
sec-policy/selinux-policykit
```

Can't forget about `/etc/portage/package.mask/pam`:
```
dev-erlang/epam
dev-ml/opam
dev-ml/opam-client
dev-ml/opam-core
dev-ml/opam-file-format
dev-ml/opam-format
dev-ml/opam-installer
dev-ml/opam-repository
dev-ml/opam-solver
dev-ml/opam-state
dev-perl/Authen-PAM
dev-php/pecl-pam
dev-python/python-pam
kde-plasma/kwallet-pam
net-mail/checkpassword-pam
sci-biology/paml
sys-auth/google-authenticator-libpam-hardened
sys-auth/nss-pam-ldapd
sys-auth/pam-gnupg
sys-auth/pam-pgsql
sys-auth/pam-script
sys-auth/pam_abl
sys-auth/pam_dotfile
sys-auth/pam_fprint
sys-auth/pam_krb5
sys-auth/pam_ldap
sys-auth/pam_mktemp
sys-auth/pam_mount
sys-auth/pam_mysql
sys-auth/pam_p11
sys-auth/pam_require
sys-auth/pam_skey
sys-auth/pam_smb
sys-auth/pam_ssh
sys-auth/pam_ssh_agent_auth
sys-auth/pam_u2f
sys-auth/pam_yubico
sys-auth/pambase
sys-libs/pam
sys-libs/pam_wrapper
```

Of course `/etc/portage/package.mask/networkmanager`:
```
kde-frameworks/networkmanager-qt
net-misc/networkmanager
net-vpn/networkmanager-fortisslvpn
net-vpn/networkmanager-l2tp
net-vpn/networkmanager-libreswan
net-vpn/networkmanager-openconnect
net-vpn/networkmanager-openvpn
net-vpn/networkmanager-pptp
net-vpn/networkmanager-sstp
net-vpn/networkmanager-strongswan
net-vpn/networkmanager-vpnc
sec-policy/selinux-networkmanager
gnome-extra/nm-applet
gui-apps/nm-tray
```

Getting there `/etc/portage/package.mask/pulseaudio`:
```
ev-python/pulsectl
media-libs/libpulse
media-libs/pulseaudio-qt
media-plugins/gst-plugins-pulse
#media-sound/apulse #we might need this
media-sound/pulseaudio
media-sound/pulseaudio-ctl
media-sound/pulseaudio-daemon
media-sound/pulseaudio-modules-bt
media-sound/pulseaudio-virtualmic
media-sound/pulseeffects
media-sound/pulsemixer
net-misc/pulseaudio-dlna
sec-policy/selinux-pulseaudio
xfce-extra/xfce4-pulseaudio-plugin
xfce-extra/xfce4-volumed-pulse
```

After that, `/etc/portage/package.mask/lvm`:
```
app-backup/mylvmbackup
sys-fs/lvm2
```

Followed up by `/etc/portage/package.mask/btrfs`:
```
app-backup/grub-btrfs
sys-fs/btrfs-heatmap
sys-fs/btrfs-progs
sys-fs/btrfsmaintenance
sys-fs/python-btrfs
```

Move b get out the way `/etc/portage/package.mask/wayland`:
```
app-misc/wayland-utils
dev-cpp/waylandpp
dev-libs/plasma-wayland-protocols
dev-libs/wayland
dev-libs/wayland-protocols
dev-qt/qtwayland
dev-qt/qtwaylandscanner
dev-util/wayland-scanner
gui-apps/wayland-logout
gui-libs/egl-wayland
kde-frameworks/kwayland
kde-plasma/kwayland-integration
kde-plasma/kwayland-server
x11-apps/xisxwayland
x11-base/xwayland
```

Last and loneliest `/etc/portage/package.mask/logind`:
```
sys-auth/elogind
```

This should about just about cover most of our bases.
I might have gone a bit overboard in a few cases but not without reason.
I'd rather block something related to the unwanted software and then find out I want to use it and need to comment it out than have to comb through all packages for any offenders.

#### Colonel trouble
Alright then with that handled we can install a kernel, a bootloader, fix up `/etc/fstab` and be on our merry way.
Sounds easy enough, right? Right?
This is coloring outside the lines expert edition, don't be naive.
If you think you should go for one of the distribution kernels, don't or else dracut comes knocking on your door:

```
emerge -av gentoo-kernel-bin

These are the packages that would be merged, in order:

Calculating dependencies... done!

!!! All ebuilds that could satisfy "virtual/udev" have been masked.
!!! One of the following masked packages is required to complete your request:
- virtual/udev-217-r5::gentoo (masked by: package.mask)
- virtual/udev-217-r3::gentoo (masked by: package.mask)

(dependency required by "sys-kernel/dracut-056-r1::gentoo" [ebuild])
(dependency required by "sys-kernel/gentoo-kernel-bin-5.15.59::gentoo[initramfs]" [ebuild])
(dependency required by "gentoo-kernel-bin" [argument])
For more information, see the MASKED PACKAGES section in the emerge
man page or refer to the Gentoo Handbook.
```

This seems easy enough to fix, `echo 'sys-kernel/gentoo-kernel-bin -initramfs' > /etc/portage/package.use/gentoo-kernel-bin`
and we get:

```
emerge -av gentoo-kernel-bin

These are the packages that would be merged, in order:

Calculating dependencies... done!
[ebuild  N     ] dev-libs/elfutils-0.187::gentoo  USE="bzip2 nls utils -lzma -static-libs -test (-threads) -valgrind -verify-sig -zstd" 9,027 KiB
[ebuild  N     ] sys-devel/bc-1.07.1-r4::gentoo  USE="readline -libedit -static" 411 KiB
[ebuild  N     ] virtual/libelf-3-r1:0/1::gentoo  0 KiB
[ebuild  N     ] sys-kernel/gentoo-kernel-bin-5.15.59:5.15.59::gentoo  USE="-initramfs -test" 190,647 KiB
[ebuild  N     ] virtual/dist-kernel-5.15.59:0/5.15.59::gentoo  0 KiB

Total: 5 packages (5 new), Size of downloads: 200,083 KiB

Would you like to merge these packages? [Yes/No]
```

#### Bootloader
It's 3am right now and I'd rather not fight a bootloader.
I'm giving up on rEFInd for the moment and installing grub.

### Booting into the system
Of all the things that could go wrong, XFS is what bit me.
I might have forgotten to install something or `gentoo-kernel-bin` doesn't support XFS.
After that I booted back into the live ISO, mounted the partitions, entered into the system, installed xfsprogs, rebooted and still no dice.
The solution that feels better to me is to just reinstall and grab the opportunity to script this as well.
I plan on doing that eventually but today is not the day so I went looking for a diffferent solution.

#### Changing the filesystem
A little scavenging online led me to a tool that says it can convert partitions from one filesystem to another, called [fstransform](https://github.com/cosmos72/fstransform).
Since the laptop's eMMC drive had ubuntu on it, I booted into there, installed `git` (which is one of the first things I usually install so you can tell how much I use that ubuntu install), `build-essential`, `g++` and `automake` then compiled and ran the software according to the instructions in the README.
With my fingers crossed, I tried booting into gentoo again and... SUCCESS!
The fstab is wrong since I forgot to change it from XFS to ext4 so some errors came up and the partition UUID is different which caused a few more errors to appear but I booted into a tty.
No matter that I never set a root password meaning I couldn't log in and didn't set up networking, this is still great news.

### Small configuration and tools
After rebooting to the gentoo installation media hopefully for the last time, I did some common basic setup.
This section of the installation did not lead to any issues but I'll briefly cover it anyway.

#### `/etc/fstab`
First order of business was 

#### Networking
I set the hostname in `/etc/conf.d/hostname`, set the usb ethernet interface to dhcp in `/etc/conf.d/net`, added a couple alternate names for `127.0.0.1` in `/etc/hosts` and installed dhcpcd.

#### System tools
The suggested defaults of `sysklogd` and `cronie` are fine with me so I installed them along with `chrony` and `ntp` for time sync.
I also installed `htop` as well as `sudo`.

#### Package management extras
I prefer `eix` for searching, `equery` and other utilites from `gentoolkit` are very useful and `eclean-kernel` is just good manners so I got all of them installed.
Don't forget to run `eix-update`.

#### User
A non-root user is good security practice and some things won't even run as root so a little `useradd -m -G users,wheel,audio,video,usb,cdrom -s /bin/bash angle && passwd angle` sets us up.

### Ready, set, go!
With all of that complete, we're ready to reboot.
When doing so, a couple `sh` errors from mdev show up and neither the wired or wireless interfaces show up.
*Back into the live media we go*.
Time to do the dance: install `linux-firmware`, re-emerge and `emerge --config` the kernel, remake the grub config and try again.
Reboot again and the problem persists.
I suspect the problem has to do with the kernel at this point, possibly because I disabled initramfs.
Serves me right for trying to take a shortcut instead of just writing a proper kernel config.
