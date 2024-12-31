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
Each computer that is part of a cluster is called a node.
A node can be part of the control plane node, be a worker node or both.
It is considered good practice to keep concerns separated so cluster workloads don't affect cluster stability.
To fulfill either role, a node will run several programs that interact with eachother.

### Control Plane
The control plane consists of components that make decisions about the whole cluster and act on events.
These components can technically run anywhere but they're usually aggregated on each control plane node.

#### kube-apiserver
#### kube-scheduler
#### kube-controller-manager
#### etcd

### Workers
The worker nodes include components that handle running Pods and providing the runtime environment for workloads.

#### kubelet
The kubelet can be considered the launcher part of kubernetes.
It is given a podspec by the API server and then it takes the appropriate action.
This translates to communicating with the container runtime to start a container.
A common interface called CRI (Container Runtime Interface) is used which makes the container runtime modular.
The communication between the kubelet and the container runtime happens through gRPC.

#### container runtime
The container runtime is what actually launches the containers that are part of a Pod.
Docker works in a similar way, the Docker daemon communicates with container runtime to start a container from a `docker run` command.
At the moment, the most popular container runtimes used with kubernetes are contrainerd and CRI-O.

### kube-proxy

### Resources or Objects

#### Pods
In kubernetes, Pod resources are the most important building block, the base unit of the system if you will.
They're sets of at least one container but potentially more.
Pods are used by other resource types such as Deployment, Horizontal Pod Autoscaler, DaemonSet and ReplicaSet.
An important thing to keep in mind is that the containers in a Pod scale together.
Due to this behavior, it is ill-advised to have an application backend and its database as two containers in one Pod.
Conversely, something like a log scraper/collector is a more fitting option since they correspond to one application instance.
Contrast this with the database example where one database serves multiple application instances.
