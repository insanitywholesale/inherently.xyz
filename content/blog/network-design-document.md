---
title: "Network Design Document"
date: 2022-07-16T18:45:44+03:00
draft: true
tags: ["networking", "homelab"]
---

## Intro
I recently started remaking my network at home and decided to publish some of the design documentation here

## VLANs
Probably overkill but certainly enough:
| VLAN | Description       | Subnet          | Gateway        |
|------|-------------------|-----------------|----------------|
| 1    | Default           | 192.168.0.0/16  | 192.168.0.1    |
| 2    | Auto VoIP         | -               | -              |
| 3    | Auto-Video        | -               | -              |
| 10   | Border Router LAN | 10.0.22.0/24    | 10.0.22.1      |
| 20   | End Devices       | 10.0.20.0/24    | 10.0.20.254    |
| 22   | Trusted           | 172.30.20.0/24  | 172.30.22.254  |
| 40   | Storage           | 10.0.40.0/24    | 10.0.40.254    |
| 50   | Servers           | 10.0.50.0/24    | 10.0.50.254    |
| 60   | Guest             | 10.0.60.0/24    | 10.0.60.254    |
| 65   | Media             | 10.0.65.0/24    | 10.0.65.254    |
| 66   | IoT               | 10.0.66.0/24    | 10.0.66.254    |
| 66   | DIY IoT           | 10.0.67.0/24    | 10.0.67.254    |
| 70   | Security          | 10.0.70.0/24    | 10.0.70.254    |
| 80   | DMZ               | 10.0.80.0/24    | 10.0.80.254    |
| 99   | Management        | 10.99.0.0/16    | 10.99.0.1      |
| 113  | MAAS              | 10.0.113.0/16   | 10.0.113.254   |
| 123  | Windows           | 10.0.123.0/16   | 10.0.123.254   |
| 150  | Test LAN          | -               | -              |
| 666  | Native            | -               | -              |
| 1022 | Unused Port       | -               | -              |
| 1337 | Danger            | -               | -              |
