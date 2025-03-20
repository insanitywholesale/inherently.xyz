---
title: "Homelab Current Form"
date: 2021-02-07T14:35:32+02:00
draft: false
tags: ["homelab", "sysadmin", "linux", "zfs", "kubernetes", "ansible", "proxmox", "terraform"]
---

The first part of the software changes I made was covered [in the first part]({{< ref "blog/homelab-evolved">}}) where I explained how and why I started going down this path.

## Software choices
This whole journey was about making my home infrastructure better.
Part of that was about having a way to more easily create the foundation on which kubernetes would run on, as well as describing my setup as code.
Proxmox is a beast in its own right. Features include being able to manage kvm virtual machines and lxc containers, an API that can be used to interact with it programmatically and most importantly being open source.
While researching what automation tools could interact with proxmox, I found a community-made terraform provider as well as a set of two ansible community modules (kvm and lxc).
After thinking about it a little bit, I wanted to use terraform in a non-cloud environment but also gather some knowledge about it so that’s what I decided to use.
I can have my provisioning requirements in a file that terraform understands and store it in git which is exactly what I was going for.
Ansible is still in the picture since it is used to set up and configure the debian environment inside the virtual machines.
Now that the hypervisor part is covered, let's move on to running services.

## Making it store is harder than making it run
As mentioned [in the first part about software changes]({{< ref "blog/homelab-evolved">}}), I was learning kubernetes and now I could not only wipe and recreate the cluster itself but also the entire virtual machines that it was running on.
Some time after starting to use proxmox with terraform I attempted to use rancher to manage kubernetes but ended up ditching it due to various problems with running even basic stuff on it (very likely that it’s a case of PEBCAK, I don’t think rancher is terrible or anything like that).

### The problem
However the problem of shared storage continued to taunt me for the following months.
There was seemingly nothing that a simple fella could do to use a nice and simple NAS running truenas core as storage that is able to be dynamically provisioned for use by kubernetes.
Now, I hear you, "what about nfs-client-provisioner", someone less familiar with this pile of madness might exclaim.
Indeed it does exist and barely work except the helm chart for it is deprecated and it does not work with kubernetes version 1.20 and later since it does not seem to be using CSI drivers.

### I really tried
Months of furious and frustrating testing ensued.
Not only was I trying to get applications running on kubernetes, I was also fighting with the unexpectedly complex tast of using the storage server I had available.
#### glusterfs
I've gone through basically any and all commonly suggested options for dynamically provisioned storage.
Prette early on I tried glusterfs with heketi by making 3 LXC containers and mounting an nfs share to each one that would serve as the brick in the gluster volume.
Suffice it to say that it didn't work and things were getting out of hand.
#### longhorn
After a bit more research and I found out that longhorn, another project by the authors of k3s, used iscsi to communicate with kubernetes.
That could work I thought, except there was no coherent example of how to use it without using targetd for iscsi.
Longhorn was starting to look more appealing, I could just put the virtual drives of the VMs on an nfs share, run longhorn inside the VMs to pool all their storage together and call it good enough.
No, I could not give up yet.
A sub-optimal solution would do if there was no other way but I was convinced something more was out there.
My patience and hope were running out but not empty yet.
#### success
That all changed in early January where during my nearly daily search for possible storage solutions I hadn’t tried, I found out about [democratic-csi](https://github.com/democratic-csi/democratic-csi).
This was it. Made to be used with freenas, truenas as well as DIY ZFS setups.
The silver bullet was here.
Just a few minutes of reading about it and writing my configs, a short(read: long) helm command later and...success!
The test pod was using the newly created storageclass that was backed by the nfs share on truenas.
After that I rushed to deploy my standard set of gitea, droneci and minecraft to test it out and it was working for real without a hitch.

## Conclusion
This was a long journey and it isn’t coming to a close any time soon.
The next step is to continuous deployment but that’s an issue for another time.
To conclude as briefly as possible, I’ve no put most of the critical pieces of my homelab in a single git repo that I can use to recreate almost all of it from scratch with minimal manual intervention (there are still a few quirks like not having dynamic inventory for ansible and having to manually copy IPs but I can put that aside for now).
Despite the imperfections like not having dynamic inventory for ansible or having secrets stored unencrypted in git, I'm very happy with the setup is working.
If you missed them, make sure to check out the [hardware updates]({{< ref "blog/hardware-updates-2020">}}) and [the first part about software changes]({{< ref "blog/homelab-evolved">}}) for a better of what I've been up to.
