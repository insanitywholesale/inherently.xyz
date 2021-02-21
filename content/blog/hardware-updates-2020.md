---
title: "Hardware Updates 2020"
date: 2021-01-15T21:10:38+02:00
tags: ["homelab", "hardware", "computers", "technology"]
draft: false
---

## Getting a real storage server
During 2020 I got a few upgrades to my setup but I don’t remember the exact order of them.
The most exciting was a 4U rackmount case that I could use to put up to 6×3.5″ hard drives by default and up to 9 with a 2×5.25″ to 3×3.5″ hotswap bay.
Also I bought 3x4TB ironwolf hard drives to put in it initially because my 2x2TB mirror was regularly reaching 95% capacity meaning I had to prune the snapshots regularly and couldn’t use it to store more files on it.
This made me warm and fuzzy inside but the old mirror had to sit on the bench for this transition.
The power supply in my server had only 4 sata connections which would be enough for a boot SSD and one of the arrays but not everything at once.
Initially that wasn’t a problem, installed truenas core on the ssd, set up the 3 4TB hard drives in a raidz1 configuration and started creating datasets and shares.

## Adding some extra spice
After a while I wanted to access the data on the old miror which meant having to buy a new power supply so I got one.
Namely the Corsair CV550 which has 7 sata power connectors, more than enough to power the five hard drives and the one SSD.
Moving on to issue number two, data connections of which the motherboard only had 4 of.
Admittedly 50 euros for an extra 4 sata ports seemed excessive but I saved up and acquired a nice and simple pcie card that did the job, no raid controller of course.
Alright, we’re cooking with gas now, storage is taken care of.

## Dealing with separation of concerns
However, I used to have a multi-purpose server and now it is just a NAS so I can’t run all my services anymore.
Fear not because the trusty old and used Dell Optiplex came to the rescue.
A shop near my house had one with an i5 2400 and 4gb of ram as well as a 250gb hard drive with windows on it for just 130 euros so I jumped on it.
First things first, I can't be using a mechanical hard drive for the operating system and proxmox doesn't dual boot so the HDD has to be replaced.
Luckily the 240gb SSD from when I originally built my desktop is still alive and it'll do more than fine for this purpose.
The hard drive will be put aside for now but rest assured I do plan to use it at some point.

## Serially accessing memories about ram upgrades
More importantly, I got a handle on the ram situation of my NAS.
Upgraded that beast from 12 to 16 gigabytes of ram which left the 4gb stick as a spare.
Not being one to miss out on some extra ram, the spare got added to the optiplex.
Going from 4 to 8 is nice but I want to run more than 2 virtual machines.
With that in mind and a deal available, I added an 8gb to the optiplex.
So we're up to 16(8+8) gigabytes for the NAS and 16(2+2+4+8) gigabytes for the server..
An odd configuration but ram is ram and you bet I’ll use it.

## Conclusion
Perfect, we had storage and now we have compute as well.
How was this hardware used though? Check back later (or read the next post if it's up) to find out.
