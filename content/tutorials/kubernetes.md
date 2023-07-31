---
title: "Kubernetes"
date: 2022-08-05T21:38:21+03:00
draft: true
tags: ["kubernetes"]
---

## Preamble
Kubernetes is a complex software stack that has been getting more and more popular.
I've spent the last 3+ years learning about it and running it at home.
This tutorial will attempt to go through its architecture and provide the reader with an understanding of how it all fits together.

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
The kubelet can be considered the launcher part of kubernetes.
It is given a podspec by the API server and then it takes the appropriate action.
In most cases this translates to communicating with the container runtime to start a container.
However, somewhat recently, kubernetes gained the ability to talk to a WASM runtime in order to run code that way.

#### container runtime

### Pods
In kubernetes, pods are the most important building block, the base unit of the system if you will.
They're sets of at least one container but potentially more.
Pods are used by other resource types such as deployment, horizontal pod autoscaler, daemonset and replicaset.
An important thing to keep in mind is that the containers in a pod scale together.
Due to this behavior, it is ill-advised to have an application backend and its database as two containers in a pod.
Conversely, something like a log scraper/collector is a more fitting option since they correspond to one application instance.
Contrast this with the database example where one database serves multiple application instances.
