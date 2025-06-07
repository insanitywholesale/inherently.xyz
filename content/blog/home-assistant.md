---
title: "Home Assistant"
date: 2025-06-07T14:12:34+03:00
draft: true
tags: ["homelab"]
---

I recently set up Home Assistant as a way to monitor the temperature in my room.
It's a really cool piece of software and took a bit of time to set up so I'd like to document everything I've changed here.

## Getting started

Home Assistant is an open-source home automation solution, possibly the most well-known in its category.
It's a great DIY and self-hosted alternative to smart home offering from bigger vendors.
As a platform it can integrate with tons of products available on the market and is very easy to run.
I've been interested in using Home Assistant for a few years but I never had anything to use it for or with.
Recently I decided I should look more into it so I ordered a little temperature and humidity monitor as well as a ZigBee stick from Sonoff.
ZigBee is a protocol that a lot of the smart home devices use to communicate, including my temperature/humidity monitor.
This means that as long nothing goes wrong, I should be able to track my room's temperature inside Home Assistant.
Sonoff also has smart power plugs, look for the ones that have `ZB` in the model number like the S26R2ZB or S60ZBTPF (I didn't check and wasted 10 euros).

I picked up the items I ordered, dusted off the old Raspberry Pi 3b+ I've had for years and installed Home Assistant OS on it.
It took about an hour because for some reason the ethernet port on the Pi decided to not work.
After facing its demons and working through the childhood neglect trauma I had given it, the ethernet blinky light blessed the little Pi.
A little network setup and ta-da! I can log in using a browser on my desktop.
Following that I shut it down, connected the Sonoff USB ZigBee stick and turned it back on.
With a few clicks the USB stick was detected and ready to be used inside Home Assistant.
I made it scan for devices and set the temperature and humidity monitor into pairing mode and then connected to it.
This was a surprisingly straightforward process and right after there was data visible in the homepage.

## Graphing the worst star's waste heat

I keep the monitoring device on my desk so I can look at it and check that I'm not going crazy and the weather is indeed getting warmer.
After few days I could look at the pretty graphs and see how the temperature fluctuated throughout the days which was quite interesting.
I could visibly see when I had opened the balcony door for some fresh air or how much the air-conditioner actually drops the temperature.
In general the whole solution works very well.
One day there was notification about a firmware updated for the ZigBee USB stick which I could install directly through Home Assistant.
I still hate warm weather and the sun and now I can track how much it's affecting me in my room.

## Add-ons

For any web interface I consider it necessary to have an HTTPs certificate and some way to remotely access it.
Thankfully using add-ons, it's possible to get certs from LetsEncrypt, use nginx as a reverse proxy and also install cloudflared.
It does require some fiddling in the YAML configuration file (using the editor add-on) but it's not too difficult.
