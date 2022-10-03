---
title: "Virtualized pfSense on ProxMox"
date: 2022-09-20T01:12:49+03:00
draft: true
tags: [""]
---

## Intro
Recently I went down the path of running my router inside a virtual machine.
This is far from the first time I've tried it but it is the first time I have a solid long-term plan.
Keep reading if you're interested in doing something similar, this should be fun.

## Background
Last time I ran my router inside of a virtual machine was in 2017 and it [was documented in this article](https://passthroughpo.st/using-vfio-turn-destkop-router/).
The reason, at least as far as I can tell, that it didn't stick is because I ran it on my desktop.
Since then, I started my homelab where I can run software on machines that are online most of the time.
A small Dell Optiplex is more than enough for my networking needs at this time and I have two of them.
I picked the weaker one since it isn't as useful for quickly spinning up and down VMs due to the old CPU.
My plan is to run some LXC containers and KVM virtual machines alongside pfSense which is why I'm virtualizing it.

## Preparation
The ProxMox installation on the weak Optiplex is configured the same as the main one for testing purposes.
When using the system as a staging environment, I installed it using ZFS.
This was a great choice for having a 1-to-1 copy of the production version but it uses a little bit more RAM than I'm willing to spare.
Due to unfortunate circumstances it's equipped with only 20GB of memory and using more than 2gb of that for the host limits what other things can run at the same time on it.
With that in mind I chose to reinstall using the default LVM scheme.
After the installation I followed the [official PCI passthrough guide](https://pve.proxmox.com/wiki/Pci_passthrough) and rebooted.

## PfSense VM Setup
Since I have 2 identical Realtek NICs but different revisions, I looked through the output of `lspci -vvvv` to identify the correct one.
With the device ID noted, I created a q35 UEFI-enabled virtual machine and made sure to uncheck the `Pre-Enroll keys` option (that one took a while to figure out).
Don't forget to set the option `Start at boot` to make it operate as if it was a bare-metal installation.
The installation process is very streamlined so I was up and running very quickly.
I had to do a little dance of plugging/unplugging cables to my switch and assign a spare VLAN to a port for setup purposes but once that was done I uploaded the backup config.
Reassigning interfaces and VLANs was a bit tedious however the whole thing didn't take more than 20-30 minutes.

## Results
The performance isn't any worse and reliability is somehow increased despite the old box using an Intel NIC and the new one using Realtek.
As far as consolidation goes, this is a huge increase and I can now run multiple other things on a single machine without relying on pfSense packages.
