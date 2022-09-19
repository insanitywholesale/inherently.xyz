---
title: "QEMU Guest Agent for Terraform on ProxMox"
date: 2022-07-27T13:38:18+03:00
draft: false
tags: ["homelab", "terraform", "proxmox"]
---

## Intro
In a [previous post]({{< ref "blog/ansible-terraform-and-proxmox" >}}) I talked about how I set up proxmox in order to be able to provision virtual machines on it using terraform.
Since then, I've improved the setup by adding qemu-guest-agent to the template images without needing to create them myself from scratch and I'd like to share it here.

## The Problem
A lot images intended for openstack or cloud use, be they debian or ubuntu or something else, do not include qemu-guest-agent by default.
This means that we either don't get to enable that integration or have to do a complex dance of provisioning the VMs with the agent disabled, installing qemu-guest-agent, turning them off, applying a terraform plan with the agent enabled and booting them back up.
Obviously that's very tedious, error-prone and time-consuming especially when creating and destroying potentially dozens of VMs for testing.
To figure out a solution, I went down a bit of a rabbit hole and considered a few solutions before settling on one so I'd like to take you through the selection process.

## The Solutions
There are multiple ways to solve this problem and there isn't really a standard go-to recommended one.
One of these might work better for your situation and that's great however I will be detailing why I didn't choose them.

### Images with qemu-guest-agent pre-installed
This was my first instinct, just find images that have it already.
Unfortunately I couldn't find a debian image that fit this criteria and overall it's not a reliable solution, some distros might simply elect to not include it.

### Terraform remote-exec provisioner
I found [this great blog post](https://cloudalbania.com/posts/2022-01-homelab-with-proxmox-and-terraform/#considerations-when-creating-vms) by Besmir Zanaj which was really interesting and demonstrates how to use terraform to achieve post-provision VM customization.
It is worth checking out however for something so basic that all virtual machines need I decided it was better to bake it into the template rather than have the action run on each VM individually.
The example from the post about firewall rules is a great use-case for this functionality so it's not to be discarded entirely.

### Packer proxmox-iso Builder
Packer is another tool from Hashicorp, the same company behind terraform, that can create images to be used with proxmox and then make templates based on those images.
The functionality is offered by a plugin, specifically a builder, called [proxmox-iso](https://www.packer.io/plugins/builders/proxmox/iso).
It didn't appear to be a terrible choice but the [configuration examples that I found](https://github.com/xcad2k/boilerplates/tree/main/packer/proxmox) relied on launching ubuntu, waiting a certain amount of time then sending keystrokes to begin a no-cloud autoinstall.
This seemed to me to be very error-prone and distro-specific so I skipped it.
I don't believe it to be a complete dead-end and it's possible there is a better way to use it for what I want but I couldn't figure out how.

### Adding qemu-guest-agent using guestfs-tools
The last thing I looked into was using guestfs-tools to modify the image before creating a proxmox template out of it.
Guest-fs tools is a set of tools for modifying virtual machine disk images that works on a lot of distros.
After lots of searching, I came across [an awesome blog post](https://austinsnerdythings.com/2021/08/30/how-to-create-a-proxmox-ubuntu-cloud-init-image/) by Austin Pivarnik which tackled basically the same problem.
As detailed in the post itself, on debian-based systems which luckily proxmox is, we can install `libguestfs-tools` and then use the `virt-customize` command to alter the contents of a virtual machine image.
How I added this to my setup:
- add `libguestfs-tools` to the list of packages installed by my proxmox setup ansible playbook
- add a task (adapted for all VM images) to the same playbook after downloading the image but before creating the template
- run playbook
- ta-da!
You can see the changes I made [in this commit](https://gitlab.com/insanitywholesale/infra/-/commit/831fe44f103c3650a41eca4722cce794e67ca741) where I also adjusted my terraform configuration and a couple other small things.
I've been very happy with this so far and aside from showing the guest IP in the proxmox web interface as well as allowing smooth shutdown it has also improved provisioning times.

## Conclusion
Having good templates for virtual machines on a virtualization platform is very important for automation.
While it took quite a long time for me to find a suitable solution I am quite happy with where I ended up and the improvement to my homelab.
Thank you for reading and I hope you learned something new.
