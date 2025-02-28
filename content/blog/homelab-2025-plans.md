---
title: "Homelab 2025 Plans"
date: 2025-02-28T22:51:33+02:00
draft: false
tags: ["homelab", "kubernetes", "proxmox"]
---

## Intro

After recapping the state of my homelab and writing down how it was in the end of 2024, I think it's time to look towards the future.
Having finally finished my thesis, I now have less constant stress to deal with and a bit more time than I've had in the last 2 and a half years.
The main goal of rebuilding my homelab is to make it an actual production environment.
This means that a few important problems need to be solved before it's considered done.
Along with that, I'm willing to lose a bit of flexibility in exchange for having something that actually works which is a bit odd for me to write but alas.

## Hardware

Over the past several years I've invested quite a bit into the hardware that already exists.
I won't go into great depth about it, all the details are in the previous post.
My homelab is housed in a 27U rack, includes a managed switch, a DIY router, 3 virtualization hosts and at least one NAS.
That is more than enough to at least get started running several services.
I will try to avoid investing in hardware this year with two exceptions, a VGA KVM and a good NIC for the router.
Other than those two additions, I plan to focus on software choice and configuration.

## Software

### Kubernetes

I'm going bare metal kubernetes.
This might seem counter-intuitive but it's actually the easiest thing to get working.
I still like ProxMox, I'm happy with the terraform provider for working with ProxMox and there is now a healthy alternative one, I use ansible at work and it's all nice but I'm looking for an even higher level of automation.
The integrations available for kubernetes are at a great point and have been for a couple of years now.
I can forego dealing with issues such as "how do I make DNS automatically update when I start running a new service" and focus more on running and using my self-hosted services.
Of course, kubernetes presents its own set of challenges and has its own quirks but I believe the tradeoff to be worth it for me.

The plan right now is to go with [Talos Linux](https://www.talos.dev/) so my hosts are nice and lean.
The entire process of installation can be automated using the [matchbox PXE server](https://matchbox.psdn.io/) and a bit of configuration and the operating system has just enough to run kubernetes and that's it.
I could of course regret this in which case I'll go back to Debian my beloved but it remains to be seen.
Initially I'll go with a simple ISO installation to get started and then I'll see if I want to take it a step further.
The kubernetes-related stuff is mostly figured out, default CNI, nginx for ingress, metallb for external IPs, flux to deploy stuff and I'll try adding renovate bot to help with maintenance.
What remains is to decide if I'm going to go with openebs or longhorn for storage but that shouldn't be too difficult or time-consuming.

### Router

The other interesting software choice is the router.
Having a dedicated machine for it seems wasteful and I'm bound to running whatever software is available for FreeBSD.
No, I'm not planning on moving away from OPNSense at the moment but I do want to start the vicious cycle again.
The plan is to have it in a VM, thus the vicious cycle, and then be able to run things like matchbox on the same machine, a different NTP server, a different DHCP or PXE server (mainly [tinkerbell](https://tinkerbell.org/) comes to mind), different DNS server ([Hickory](https://github.com/hickory-dns/hickory-dns) seems quite interesting) and so on.
Those could be containers inside other VMs or whatever else, I'm not bound to whatever is packaged for FreeBSD or even specifically for OPNSense.
This of course requires a hypervisor (ProxMox makes a comeback) and a NIC that can be passed through to a virtual machine in order to run the router.
This is a secondary concern since I do have an old machine from the core2duo days if I just want to runs some basic network infrastructure like the ones mentioned previously for experimentation purposes.
VyOS has also been on my mind but that's a bigger jump and would require quite a bit of effort to adapt everything I have to it.
The router plans are unclear at the moment so it's more of a backburner project.

## Conclusion

One must imagine Sisyphus, he rolls the rock and I rebuild my homelab.
Was there a point to writing this? I'm not sure.
These are my plans at the moment so I can get back into the hobby.
If I do go through with them, I'll try to document the experience when I have something workable.
