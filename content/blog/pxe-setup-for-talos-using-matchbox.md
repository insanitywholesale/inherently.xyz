---
title: "Draft: PXE setup for Talos Linux with Matchbox"
date: 2025-03-01T19:00:33+02:00
draft: false
tags: ["homelab", "kubernetes", "networking", "pxe", "opnsense"]
---

Join my campaign of hate against installing operating systems interactively.
I usually wipe my homelab virtualization hosts every week or two.
This might sound insane but I've been working on automating their setup.
As explained in the previous host, friendship ended with ProxMox and kubernetes will take its place.
Specifically Talos Linux, a linux distro you can't even SSH into.
ProxMox kind of notoriously doesn't have a way to be sanely installed through PXE but Talos is kind of made for it.
However, PXE (and iPXE, we'll discuss this later) is not perfectly documented and can be even harder to debug.
So in this post I'll document what worked for me and talk about some pretty helpful resources.

## Holy Grail

### Pixie who?

So let's start with a bit of background, then lay out what I wanted to achieve, why and what I considered "good enough".
First off, PXE.
It stands for pre-boot execution environment and is mostly reliant on motherboards and network cards to be implemented on the client side.
It's a stripped down environment before the computer is booted into an operating system.
Inside it, there are standards for getting information about what to execute, where to get it and what configuration to use.
PXE is the name of the general concept and the first version of the technology.
It allows booting a computer from the network by loading files from a TFTP server.
Later on, [iPXE](https://ipxe.org/) came around to fix some of its limitations.
One thing it's useful for having a computer and being able to boot it from the network and install an operating system on it without having to have a USB stick on you.
With something like [syslinux](https://syslinux.org/) you can even create menus to be able to choose what to install and have a bunch of different options with different settings.
As computer installations grow larger, it's easy to see how this becomes kind of essential as you can't run around multiple datacenters any time something needs to be re-imaged.
A counter-point to that could be that servers have remote management features allowing us to load ISOs as if they're DVDs but even then, iPXE has an advantage because you can fully automate the process.
Also my poor version of servers (read: used office PCs) do not have IPMI.
At any rate, that's the general idea of PXE.

### Talos

How does that apply to my case then?
I want to be able to completely wipe all three systems and then effortlessly restore them.
As I plan to run kubernetes on it, the installation of applications to the cluster is taken care of using [FluxCD](https://fluxcd.io/) so I only really need to solve the installation part.
That's where [Talos](https://www.talos.dev/) comes in.
Talos is an incredibly minimal linux distribution that is designed with the sole purpose of running kubernetes.
No SSH, no TTY, no nothing.
Sitting in front of the system only allows you to change kernel boot parameters and the network configuration.
Everyhing is done using the API which is accessible interactively through the `talosctl` CLI utility.
This means that we can have our operating system and kubernetes configuration as code for the price of one config file.
Sign me up!

### Cooka da pasta

Those are the ingredients but it can hardly be called a meal.
We need to get some kitchen utensils in this analogy to get the desired result.
Our PXE setup will need to have a little bit of logic in it so it knows what to install with what configuration.
See, Talos can be told to fetch a configuration file from an HTTP server using a kernel parameter.
A conditionally-rendered file would allow us to alter the response depending on who's requesting it.
This is where [matchbox](https://matchbox.psdn.io/) slots in.
When matchbox gets a request it can see some information about the host requesting it and therefore make a determination about what to reply with.
We can then serve different options according to which system is asking such as what Talos configuration file to use.
This way the control-plane kubernetes nodes can receive the Talos `controlplane.yaml` while worker nodes get the `worker.yaml`.
So a brand-new host with an empty disk drives would boot up, skip the disks since they don't have an operating system and then try booting using PXE.
Then the host would get its configuration, install the operating system, install kubernetes and become part of a cluster.

### Definition of Done

The ideal end solution should look like:
* note down the MAC address and corresponding IP somewhere
* plug in the cables
* configure the boot option order
* play minecraft until the host shows up in `kubectl get nodes`

I don't know if I can get exactly to that point but I'm willing to put in some effort into the setup so in the future I can avoid it to a greater extent.
Some compromise is acceptable since I don't have any IPAM infrastructure in place already so this isn't the full and proper way to go about it.

## How do I do X in Y minutes

### The gist

Meat and potatoes first, for quick reference here is what I did (5-6 hours of suffering omitted for brevity):
* Installed `tftp-hpa` on Arch
* Downloaded [undionly.kpxe](http://boot.ipxe.org/undionly.kpxe) and [ipxe.efi](http://boot.ipxe.org/ipxe.efi)
* Put them in `/srv/tftp`
* Created `matchbox.ipxe` with the following contents:
  ```
  #!ipxe
  chain http://10.0.20.50:8080/boot.ipxe
  ```
* Installed `matchbox` using Docker by running the following command:
  ```
  docker run --net=host --rm -v /var/lib/matchbox:/var/lib/matchbox:Z -v /etc/matchbox:/etc/matchbox:Z,ro quay.io/poseidon/matchbox:v0.10.0 -address=0.0.0.0:8080 -log-level=debug
  ```
* Downloaded [vmlinuz-amd64](https://github.com/siderolabs/talos/releases/download/v1.9.4/vmlinuz-amd64) and [initramfs-amd64.xz](https://github.com/siderolabs/talos/releases/download/v1.9.4/initramfs-amd64.xz)
* Put them in `/var/lib/matchbox/assets`
* Download `talosctl`
* Run `talosctl gen config homecluster https://10.0.50.69`
* Edit `controlplane.yaml` until it looks good
* Put `controlplane.yaml` in `/var/lib/matchbox/assets` as well
* Create `/var/lib/matchbox/profiles/control-plane.json`:
  ```json
  {
    "id": "control-plane",
    "name": "control-plane",
    "boot": {
      "kernel": "/assets/vmlinuz",
      "initrd": ["/assets/initramfs.xz"],
      "args": [
        "initrd=initramfs.xz",
        "init_on_alloc=1",
        "slab_nomerge",
        "pti=on",
        "console=tty0",
        "printk.devkmsg=on",
        "talos.platform=metal",
        "talos.config=http://10.0.20.50:8080/assets/controlplane.yaml"
      ]
    }
  }
  ```
* Create `/var/lib/matchbox/groups/control-plane.json`:
  ```json
  {
    "id": "kube01",
    "name": "kube01",
    "profile": "control-plane",
    "selector": {
      "mac": "18:03:73:2a:d8:a2"
    }
  }
  ```
* In [OPNSense (link to my router)](https://opnsense.home.inherently.xyz/services_dhcp.php?if=opt2)
  * Under `DHCP Static Mappings for this interface.` add the hosts
  * Under `TFTP server`:
    * Set TFTP hostname: 10.0.20.50
    * Set Bootfile: undionly.kpxe
  * Under `Network booting`
    * Set next-server IP: 10.0.20.50
    * Set default bios filename: undionly.kpxe
    * Set iPXE boot filename: matchbox.ipxe
* Boot Optiplex
* Wait
* Watch text scroll on screen
* ???
* No profit, I spent my Saturday doing this

### What do the config files mean, Mason?

# TODO: Finish this
