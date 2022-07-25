---
title: "Network Design Document"
date: 2022-07-16T18:45:44+03:00
draft: false
tags: ["networking", "homelab"]
---

## Intro
I recently started remaking my network at home and decided to publish some of the design documentation here

## Network Layout
VDSL Internet comes in through an RJ11 port to a Vodafone H300s modem-router.
LAN port 2 of the H300s is plugged into port 2 (untagged VLAN 10) of the Netgear GS724Tv4 switch.
Switch port 23 (untagged VLAN 1, tagged in all other VLANs) is plugged into the gigabit ethernet port of the pfsense router.
All devices are plugged directly into the switch since they fit.
Inter-VLAN routing happens through pfsense and the switch operates as a managed L2 switch even though it has L3 capabilities.

## VLANs
Probably overkill but certainly enough:
| VLAN | Description       | Subnet          | Gateway        | DHCP range from pfsense |
|------|-------------------|-----------------|----------------|-------------------------|
| 1    | Default           | 192.168.0.0/16  | 192.168.0.1    | 192.168.1.1-254         |
| 2    | Auto VoIP         | -               | -              | -                       |
| 3    | Auto-Video        | -               | -              | -                       |
| 10   | Border Router LAN | 10.0.10.0/24    | 10.0.10.1      | -                       |
| 20   | End Devices       | 10.0.20.0/24    | 10.0.20.254    | 10.0.20.10-245          |
| 22   | Trusted           | 10.0.20.0/24    | 10.0.22.254    | 10.0.22.22-222          |
| 30   | Monitoring        | 10.0.30.0/24    | 10.0.30.254    | -                       |
| 40   | Storage           | 10.0.40.0/24    | 10.0.40.254    | -                       |
| 50   | Servers           | 10.0.50.0/24    | 10.0.50.254    | -                       |
| 60   | Guest             | 10.0.60.0/24    | 10.0.60.254    | 10.0.60.2-252           |
| 65   | Media             | 10.0.65.0/24    | 10.0.65.254    | 10.0.65.2-252           |
| 66   | IoT               | 10.0.66.0/24    | 10.0.66.254    | 10.0.66.2-252           |
| 67   | DIY IoT           | 10.0.67.0/24    | 10.0.67.254    | 10.0.67.2-252           |
| 70   | Security          | 10.0.70.0/24    | 10.0.70.254    | -                       |
| 80   | DMZ               | 10.0.80.0/24    | 10.0.80.254    | -                       |
| 99   | Management        | 10.99.0.0/16    | 10.99.0.1      | -                       |
| 113  | MAAS              | 10.0.113.0/16   | 10.0.113.254   | -                       |
| 123  | Windows           | 10.0.123.0/16   | 10.0.123.254   | -                       |
| 150  | Test LAN          | -               | -              | -                       |
| 666  | Native            | -               | -              | -                       |
| 1022 | Unused Port       | -               | -              | -                       |
| 1337 | Danger            | -               | -              | -                       |

## Conclusion
That's my home LAN currently, I'll try to keep this updated as I change stuff but no promises.
