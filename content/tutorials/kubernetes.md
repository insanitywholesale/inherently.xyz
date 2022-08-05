---
title: "Kubernetes"
date: 2022-08-05T21:38:21+03:00
draft: true
tags: ["kubernetes"]
---

## Preamble
Kubernetes is a complex software stack that has been getting more and more popular.
I've spent the last 3+ years learning about it and running it at home.
This tutorial will attempt to go through the architecture of it and provide the reader with an understanding of how it all fits together.

## Baseline
While kubernetes distributions exist, for the purposes of explanation and demonstration, upstream kubernetes will be used.

## Architecture 

### Control Plane

#### kube-apiserver
#### kube-scheduler
#### etcd

### Nodes

#### kubelet
#### container runtime
