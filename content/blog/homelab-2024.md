---
title: "State of Homelab 2024"
date: 2025-01-27T22:38:48+02:00
draft: false
tags: ["homelab", "kubernetes", "proxmox", "ansible", "terraform"]
---

When operating a homelab there is always something new to do or something waiting to be fixed.
This post's aim is to detail the state of my homelab at the end of 2024 and beginning of 2025.

## Router

The previous post was about virtualizing pfSense inside ProxMox but this setup is no longer in use.
In its place, there is a new system running OPNSense on bare-metal.
This was done for a few reasons, the main one being that I wanted to move away from pfSense.
More than that, there was a circular dependency where the ProxMox host had to be up in order for the router to function but in order for the cluster nodes to talk to each other, the router needed to be online.
In practice this was not a huge issue but it bothered me since it made experimenting more difficult because recreating the cluster meant taking down the router as well.
I've lost a few things, mainly pfblocker-ng and native tailscale integration but they're not as big of a loss as I had anticipated.
In the end I think it was worth it, over the course of the past few years the company making pfSense has acted against the best interest of pfSense users and I did not feel like using their software anymore.

## Virtualization

I'm still running ProxMox, although now it is a 3-node cluster.
I've spent a pretty significant amount of time tweaking the bootstrap process from a fresh install to having the entire homelab operational.
Somewhere along the line I tried making it so non-cluster operation of multiple hosts was supported but gave up on that eventually.
Each of the nodes has a 250GB SSD used as a boot drive and for node-local storage along with a 2TB HDD used as a Ceph OSD.
Since the last post about using ansible and terraform with ProxMox, I've figured out the process of adding tools to the debian image in the virtual machine template.
There is also the option to deploy using GitLab CI so just making committing and pushing to the repo is enough to create a new virtual machine.
The k3s virtual machine terraform configuration was improved significantly but I've not adopted modules yet which seems to be the next step for organization-related improvements.
I also run all software directly on top of debian virtual machines without containers to practice writing ansible.
At work, our team runs everything in Docker so it could be a good idea to start moving to something similar at home for the sake of practice.

## Kubernetes

The kubernetes cluster got a significant update.
I've adopted FluxCD to a greater degree, figured out secrets storage and a pretty good structure for the YAML files.
The k3s cluster has 3 control plane nodes and 3 worker nodes, one per virtualization host.
I'm using longhorn for storage with plans to try and use the Ceph cluster as an additional storage class.
The networking setup consists of MetalLB to have an IP in the subnet and then run ingress-nginx as the ingress controller on that IP.
No plans for checking out Gateway API have been made at current but it is a good and necessary step forward in the ecosystem, I plan to move to it after things are a bit less in flux.
The DNS is manual right now due to the low amount of services but I've tested external-dns with PiHole and I'm aware of the OPNSense webhook option, it remains to be seen what I'll end up using.
The setup needs a bit more tender love and care but it's running well and doing what I need it to.
I have plans to move more stuff to the cluster after the foundation is solid and not just have my own demo applications in there.
The thought has crossed my mind to completely do away with ProxMox and then run Talos Linux bare metal on the systems but I'd be losing out on some flexibility which I don't want to commit to right now.
All in all, kubernetes is still pretty fun and the 1.30 and later releases have made good quality of life improvements.

## NAS

Since I upgraded my desktop, the old one's internals were transplanted to a different case are now a second NAS.
I'm saving up to get a big external drive so I can have an extra copy of the current main NAS so I can freely mess with them to have a solid backup solution.
The changes in TrueNAS Scale regarding applications has left me waiting for things to settle down before I commit to a final setup.
Overall nothing exciting on this front.

## Hardware

I run mostly used office desktops and a basic managed switch.
I have 3 Dell Optiplex machines: 2nd gen, 3rd gen and 4th gen Intel i5 CPUs with RAM sizes ranging from 16 to 32GB each.
For storage they have a 250GB SSD and a 2TB HDD as mentioned earlier.
The router is a Fujitsu equivalent desktop with a 4th gen Intel Pentium and 8GB of RAM as well as a 500GB SSD.
My rackmount NAS is an i5 4570 with 16GB of RAM and 4x4TB HDDs in a 3-drive ZFS RAID-Z1 plus one hot spare.
My backup NAS is an i7 4770 with 32GB of RAM and 2x8TB HDDs in a 2-way ZFS mirror.
The main network switch is a Netgear GS724TV4, just a layer 2 managed gigabit switch.

## Conclusion

I wanted to write all of this down to have a reference for myself when I inevitably change something and it might help someone else as well.
Also the blog is back(?) after more than a 2 year silence, hopefully I will not neglect it for that long again.
