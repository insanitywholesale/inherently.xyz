---
title: "Computers Were Faster"
date: 2020-12-29T17:10:41+02:00
draft: false
tags: ["old", "hardware", "computers", "technology"]
type: blog
---

In the previous post I ranted about how most software is trash and that's the cause of computers being slower than they were 10-15 years ago.
I briefly mentioned a couple 32-bit computers I own but in total they're 3 operational ones.
The PIII one is lagging behind the socket 478 based ones which are much closer to usable for most of my use cases.
How can that be one might rightfully wonder.
Computers with less than 4GB of RAM and 2 cores are completely unusable and nobody should ever touch them, a "muh modern" advocate might cry.
However I use those computers at least once a week for various tasks.
First off, as a 32-bit docker registry. They don't need to mix with the rest of the environment since there is no actual dependency between the 32bit and 64bit infrastructure.
In addition, I can see how long it takes to build a certain image based on my software, test its performance and experiment with multi-architecture images.
I would do the same thing for the raspberry pi but I only have one and that is not enough to warrant the effort.
If the above wasn't enough, they are very useful for testing things such as bare metal provisioning with a mostly DIY setup, how to configure new things I'm interested in such as the aforementioned DIY bare metal provisioning solution as well as new software stacks like ELK or TIG.
They are also useful for API load testing and discovering where the bottlenecks are in a piece of software.
On a newer multi-core cpu with loads of RAM and fast storage the bottleneck only shows up when the workload origanically overwhelms the software.
However on a more limited system it becomes apparent very quickly where the bottleneck could be.
For example, if the hard drive access is more than it should be, you hear the damn thing click every time so you know where to look.
In addition, old computers make great routers. Routers? They're old and weak computers you might think.
Well, that anemic MIPS or ARM based all-in-one network box that many ISPs provide you with has a CPU that is orders of magnitude slower than either of my 32bit boxes. For the router use case the same thing applies to the amount as well as speed of RAM.
In fact, that's how I originally got into DIY and selfhosting.
The case that used to hold my server had one of the 32-bit motherboards and cpu and ram as well as a hard drive.
After finding about pfsense and having that computer as a spare, naturally, I gave it a try.
A quick install of pfsense later and I was learning about DNS, DHCP, ARP requests, MAC addresses, gateways, how to set up an access point and started my journey into learning about networking.
Another use that requires a somewhat low-cost investment is getting a picoPSU or microPSU or something to that extent to power one of those 32-bit machines, connect it to a TV and use it as a dashboard display for monitoring software.
That's not the end and imagination is the main limit into making this sort of hardware perform a useful task.
In conclusion, before you go around calling older computers obsolete, check if PEBCAK is the bottleneck.
Thank you for reading, if you have a cool project using older hardware, feel free to let me know.
