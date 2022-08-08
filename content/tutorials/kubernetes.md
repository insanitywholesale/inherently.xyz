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
A host participating in a kubernetes cluster can be a control plane node, a worker node or both.
It is usually advised to keep concerns separated so cluster workloads don't affect cluster stability.

### Control Plane

#### kube-apiserver
#### kube-scheduler
#### kube-controller-manager
#### etcd

### Workers

#### kubelet
#### container runtime

### Pods
In kubernetes, pods are the most important building block, the base unit of the system if you will.
They're sets of at least one container but potentially more.
Pods are expanded upon by daemonset, replicaset, deployment, horizontal pod autoscaler and other kubernetes objects.
An important thing to keep in mind is that the containers in a pod scale together.
Due to this behavior, it is ill-advised to have an application backend and its database as two containers in a pod.
Conversely, something like a log scraper/collector is a more fitting option since the logger corresponds to one application instance while the database should serve multiple instances.
