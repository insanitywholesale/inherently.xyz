---
title: "Reinstalling Gentoo"
date: 2021-03-10T00:54:04+02:00
draft: false
tags: ["desktop", "linux", "gentoo", "zfs", "ansible"]
---

## Why
This gentoo install has lasted a good long couple of years.
There is nothing really wrong with it, the SSD it's installed on is a bit full and it's a good opportunity to make a change.
However I'm looking to shake things up a bit.
The big change is installing on ZFS this time.
It's fairly well-known that I'm a big fan of ZFS, my storage server has been using it in one form or another sinc forever and all of my home infrastructure directly or indirectly depends on it.
However it is not the only change being made, executing the install using ansible will be a good improvement too.
One of the issues with gentoo, to people that have been using it for a while, is the seeming non-repeatability of the install.
A script can get really close however certain steps are not as easy to get right and everything is highly procedural instead of declarative or idempotent way.
The other changes will include moving to a system with as few, as I view them, harmful or unnecessary componenets.
Stuff like dbus, eudev, elogind, pulseaudio, systray and a few other things that I'm in the process of nailing down will be (hopefully) gone.

## How
### Ansible
First off, the ansible playbook. There are a few different ones floating around but are outdated or don't fit my needs.
Of course that doesn't mean I can't examine the pre-existing solutions, I will absolutely take inspiration from solutions that smarter people have come up with.

### ZFS
The most important decision will be the layout.
I know I'll be using docker and libvirt so adjustments to /var/lib are needed.
Also, the system needs to be bootable and usable to some extent even if the ZFS kernel module doesn't get loaded.
There are 2 different solutions to this, either go with EXT4/XFS or just build ZFS into the kernel.
I'm still undecided about the route I'll go with but remain open to experimenting and seeing which one is better.

### Cruft removal
Several components are impacted here.
The most interesting one I'm looking forward to installing is [libudev-zero](https://github.com/illiliti/libudev-zero) to seemingly satisfy any dependencies that require (e)udev while in reality using busybox mdev.
This gets rid of some dependency problems with libinput/evdev and anything else that has a hard dependency on a single device manager implementation without source code patches to those projects.
It also give me the ability to use input classes in xorg instead of hardcoding device paths which is something that was somewhat annoying last time I tried switching away from eudev.
As for the rest, I'm testing out what can be effortlessly removed and what requires significant changes to one thing or another on my laptop.
We'll see what I end up with, I'll update this post after it's up and running.

## Conclusion
I've enjoyed my gentoo system for multiple years at this point but I want to make things better so I'll be reinstalling and starting from a clean slate.
Switching the filesystem to the one my storage server relies on will be pretty sweet (I might also look into some pre or post package install hooks).
The installation process, and hopefully the full system setup, will be described using ansible to make it more easily repeatable
And finally, any piece of software I don't like or use will be removed or replaced and incompatibilites fixed along the way.
I look forward to a better gentoo system in 2021.
