---
title: "Remote Access Homelab"
date: 2025-05-04T18:26:25+03:00
draft: false
tags: ["homelab", "kubernetes"]
---

One of the remaining things for my homelab to have is remote access.
I set up a couple options and faced some issues during the process which I want to document here.

## Tailscale

Tailscale is wireguard-based VPN solution.
Its main idea is that you run it alongside whatever you want to be accessible in your tailscale virtual network and then you can get to it.
My primary concern was replacing something like openvpn where it can be set up so it's almost like being connected to the local network.
In tailscale this can be achieved by making it announce that it can route to a specific subnet.
This way things like local DNS works normally (for example I can access `opnsense.home.inherently.xyz`and see the web interface of my router).
Additionally, you can make your traffic be routed through a specific device.
This might be the router at home which will be marked as an exit node and then in the mobile app select it to be used as such.
The choice of tailscale dates back to when I was still running pfSense.
In pfSense there has been a built-in integration for quite a while that can work as an exit node and subnet router.
In OPNSense it used to require a very manual install and setup process through the FreeBSD ports system but now there is a plugin which is a lot more user-friendly.
I set it up that way and then joined my phone and my tablet to the tailnet which means I can access all of my servers remotely.
Problem solved, let's go home, roll the outro.
Not yet.
The thing is that while this works fine for just myself, if I want someone to check out some new selfhosted service I have or connect to a database I'm hosting I don't want them to have to set up tailscale first.

## Cloudflare Tunnel

To address that need, I chose Cloudflare Tunnel.
This works a bit differently than Tailscale, you run cloudflared and tell it where traffic for a domain name should be redirected.
In my case it runs inside kubernetes and points to the ingress controller.
This... took a while for me to get working.
It was mostly my own fault and lack of knowledge of how cloudflare works.
There are certificates that cloudflare generates which encrypt traffic between clients and cloudflare.
This process is done automatically and only for the root domain, for any subdomains you better get your wallet out.
This meant that since I was trying to access services that were something like `service.home.inherently.xyz`, TLS was broken.
Took about 2 days to figure this out and I only managed it thanks to Kryptonian in the Home Operationsdiscord server.
The way I fixed the TLS problem was by just putting everything under the root domain which then made it work.
There is a bit more work to do because I think [cluster-template](https://github.com/onedr0p/cluster-template) does have a good idea with separating services that should be externally accessible by running two ingress controllers.
However, at this point it gets the job done so I'm reasonably happy with it.

## Conclusion

Access do be external.
