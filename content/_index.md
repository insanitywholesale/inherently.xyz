---
title: "Home"
date: 2020-12-13T20:37:02+02:00
tags: ["index"]
draft: false
---

## What I do

Most of the time I'm tinkering with something technology-related that is interesting to me.
I started playing around with setting up servers when I was 13-14 and only got more into it from there.
My passion for productive and effective use of technology led to me discovering the world of
[libre software](https://www.fsf.org/resources/resources/what-is-fs)
and
[self-hosting](https://www.reddit.com/r/selfhosted/wiki/index#wiki_self-hosting).
Eventually I realized that it was something I could do all day and never be bored and thus began my studies in the field.
Up to this point I've tried many technologies including but not limited to
linux, zfs, qemu+kvm+libvirt, proxmox, openstack, pfsense, git, ansible, terraform, lxc, lxd, docker, docker-compose, kubernetes, freenas/truenas, glusterfs, ceph

check out what else is on the site by
[clicking here](/links)
or in the links section on the top bar.

---

## Personal Projects

I'll make an attempt to document my journey as far as programming and sysadmin experiences.
This will have missing and slightly inaccurate information as I'm doing this all in one go.
My contact information is available on the contact page so feel free to ask me about anything and I'll do my best to answer.
The source code for most if not all of the following things (where applicable) is on my github or gitlab so take a look there.
With all disclaimers out of the way, let's get into it. 

---

### Programming

Over the years, I've used plenty of programming and scripting languages.
I have a soft spot for POSIX-compliant shell scripts and YAML since that's what I write most of the time.
However, my experience is far from limited to one thing when it comes to programming.
Initially, I started out with shell scripting when I was 15-16 and that was most of my experience with programming until university.
There I found out that despite the negative opinion of the wider programming community, I liked Java.
After making a couple silly programs with java, I decided to try tackling a more "modern" stack.
To that extent, I tried reactjs and nodejs and ended up making an incomplete (as of now) messaging site.
Not satisfied with the previous experience and with a bit of research I set my sights on golang.
Barely a week had passed yet I had made a couple web-based services that despite their simple function, were fairly advanced as far as architecture was concerned.
Working more with it, I enjoyed the software design patterns that could be easily implemented as well as the language itself.
All of this was a very good departure from the javascript world.
Following that, I decided to go back and see how Java could compare in this domain.
Toying around with the spring boot framework was interesting and so was using something simpler -- jersey.
Apparently I liked tinkering with microservices in general.

---

### Sysadmin

Enough about programming, time to get into system administration.
There are few things I find as enjoyable as figuring out how a system works and setting it up.
Everything from a small Raspberry Pi running an NFS share to an older desktop with a couple virtual machines to multi-master kubernetes clusters is interesting to me.
Understanding what parts need to fit together and in what way is a puzzle-solving exercise familiar to most technology enthusiasts.
For me it's an ever-expanding hobby, always more to learn, new approaches to try and that's what keeps it exciting.
Currently, all of my knowledge has come out of using things at home.
It all started with installing and trying out Linux when I was 13 because of a random article I read online.
A year or so later, I was already setting up an old 32-bit computer as a router using pfsense.
Somewhere in there I tried vmware esxi for a couple months before moving to proxmox (was using OpenVZ instead of LXC back then).
It wasn't long before I was using Linux on every computer I had and inside virtual machines.
Playing around with setting up LAMP stacks, FTP servers, configuring secure SSH access with keys, nextcloud, dokuwiki and more.
You can always find me reading about something, always finding out new information about something. 
My homelab hasn't stopped expanding and evolving, in a constant state of flux yet always present.
There is no reason to stop setting up and configuring more applications and services, writing ansible playbooks or improving existing infrastructure.
Invariably, it's an endless amount of fun no matter the difficulty and frustration.
However, this wasn't always the case, I had "settled down" to using one VM for each application or service that I wanted to run.
Then at some point I started noticing a trend of newer technologies, a more efficient way to self-host.
This Docker thing was really catching on so I installed it and started tinkering.
Not more than a couple months later I was running my website using docker-compose using traefik as a reverse proxy.
However, I knew I wasn't going to stop there. How do I keep all my stuff running reliably?
Kuberentes was a natural fit for the task.
By now my experience with it is limited but in an effort to run everything on it, I've written YAML manifests, set up a continuous integration and continuous delivery pipeline on a test cluster to deploy several services to it.
My Raspberry Pi runs k3s, every single one my non-server computers has either minikube or kind installed and I'm writing kubernetes-friendly microservices.
To not waste any more time let's just say it's been very fun tinkering with all of this and also very educational.
