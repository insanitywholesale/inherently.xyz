---
title: "Homelab Evolved"
date: 2021-02-07T13:53:10+02:00
tags: ["homelab", "computers", "technology", "linux", "zfs", "kubernetes", "ansible"]
draft: false
---

## Previous revelevant post
The hardware side of the changes made to my homelab were covered [in a previous post]({{< ref "blog/hardware-updates-2020" >}}) where I also alluded to some software changes.

## What came before
This is the first part explaining more in-depth the issues that I had and how I dealt with them.
Let's set the stage first, my homelab was working fine in many ways.
It was nice and stable debian install running kvm virtual machines using qemu and libvirt with virt-manager to perform the simpler start/stop tasks.
There was really nothing wrong with it, I was exploring different software, running some services on the local network and even hosting a public website on it.

## Good enough is not good enough
However as someone interested in infrastructure a few things were bothering me.
Sure, I was using docker-compose with traefik for my public website and services.
Yes, I was using ansible to manage the configuration of most virtual machines.
But "good enough" and "I guess it works" doesn't cut it.
On the upside, I really liked having ZFS snapshots on a 2x2TB mirror.
The ability to go back to a point in time where things were not broken had saved me a couple times when I inevitably broke one thing or deleted a file that could be replaced but would take a while.
My backups were also on that ZFS mirror, on a different dataset of course, and that also very useful.
I knew I wanted ZFS and that there was much room for improvement in regards to handling how I was running services. The single docker-compose virtual machine for the public stuff and another one for local stuff were mostly adequate but the manual management was not.
Not to mention that and all my precious stuff was on one box which is well below ideal.

## Taking the step
One day I decided it was time to move up in the world.
Despite using docker and docker-compose for years I had never dived into kubernetes because it seemed difficult and complex.
New syntax, new system with its own architecture and internal structure, new workflow, new everything.
I decided to set up 3 VMs and played with default k8s as well as k3s on them.
Dipping my toes into it was pretty fun and since nothing depended on it I was free to wipe it and start over.
The same issue kept cropping up, having to manually install debian thrice and set up kubernetes just to delete all of it and redo it was again, less than ideal
Initially I started writing a playbook before finding out that someone smarter had already gone down this path.
Setting up [k3s-ansible](https://github.com/k3s-io/k3s-ansible) was easy so there was at least kubernetes setup automation but the whole thing was too thrown together there was no shared storage.
However, I was becoming more familiar with kubernetes and learning the concepts as well as how to write yaml manifests.

## Conclusion
At some point it became too bothersome, a lot of manual work was involved and basic stuff like copying over ssh keys was also done mostly manually so I had to move on.
While all of this was going on, I had started planning what hardware updates I would get which you can read about here: [Hardware Updates 2020]({{< ref "blog/hardware-updates-2020" >}})
