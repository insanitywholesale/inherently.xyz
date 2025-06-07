---
title: "Home Assistant"
date: 2025-06-07T14:12:34+03:00
draft: false
tags: ["homelab", "homeassistant"]
---

I recently set up Home Assistant as a way of getting into home automation.
It's a really cool piece of software and took a bit of time to set up so I'd like to document everything I've changed here.

## Getting started

Home Assistant is an open-source home automation solution, possibly the most well-known in its category.
It's a great DIY and self-hosted alternative to smart home offering from bigger vendors.
As a platform it can integrate with tons of products available on the market and is very easy to run.
I've been interested in using Home Assistant for a few years but I never had anything to use it for or with.
Recently I decided I should look more into it so I ordered a SNZB-02D temperature and humidity sensor as well as a ZBdongle-E ZigBee stick also by Sonoff.
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

A couple weeks later I picked up another two sensors and two zigbee power plugs.
As a word of advice, the S26R2ZB is cheap so it only supports on/off functionality and not power measurement.
The S60ZBTPF should support both though, I have the non-ZigBee version and it does but only using eWeLink.

## Graphing the worst star's waste heat

I keep the monitoring device on my desk so I can look at it and check that I'm not going crazy and the weather is indeed getting warmer.
I also have one out in the balcony and one in the living room.
After few days I could look at the pretty graphs and see how the temperature fluctuated throughout the days which was quite interesting.
I could visibly see when I had opened the balcony door for some fresh air or how much the air-conditioner actually drops the temperature.
In general the whole solution works very well.
One day there was notification about a firmware updated for the ZigBee USB stick which I could install directly through Home Assistant.
The sensors also had a firmware update and could also be updated directly through HomeAssistant.
I don't know why this seems like such a big deal to me but it's surprising to see this process be supported and vendors not pulling some bs for once.
I still hate warm weather and the sun but now I can track how much it's affecting me.

## Add-ons

For any web interface I consider it necessary to have an HTTPs certificate and some way to remotely access it.
Thankfully using add-ons, it's possible to get certs from LetsEncrypt, use nginx as a reverse proxy and also install cloudflared.
Cloudflared is not official but it does work well even if it was a bit troublesome to set up initially.
It does require some fiddling in the YAML configuration file (using the editor add-on) but it's not too difficult.
I also enabled prometheus metrics, which require authentication to scrape so it will be a slight bit more complicated than usual but nothing unusual.
There is a lot of other software available as an add-on, many things which I don't care to run on Home Assistant on my Raspberry Pi, but it's good to see such robust support and that they are available for use cases where they make sense.

## Later expansion

I plan to add more stuff in the future and start playing with automations.
Currently it's just a couple lights, the sensors and the power plugs.
There is no inclination to do something extra with them, just having control of all of them through one place is helpful enough.

## Conclusion

It's a cool setup that works for what I want to do right now and also has a lot of room for expansion.
Now that I can access it from the outside and have TLS certificates it been a very nice experience.
If you've been waiting to start as well, it's a lot easier than you might think.
