---
title: "Talos Linux Setup and Configuration"
date: 2025-03-11T19:28:45+02:00
draft: false
tags: ["homelab", "kubernetes"]
---

After about two weeks since the first time I installed Talos, I think I've figured out a good setup.
In the previous post I went over the PXE setup more than the kubernetes part of it so now I'll cover the other half.

## How the Talos configuration works

Following [the getting started guide](https://www.talos.dev/v1.9/introduction/getting-started/) tells us that to generate the configuration files we need to run something like `talosctl gen config homecluster https://10.0.50.69:6443`.
This command will generate 3 files. These are `controlplane.yaml`, `worker.yaml` and `talosconfig`.
The control-plane nodes will use the first file, the worker nodes will use the second file and the third one should be placed into `~/.talos/config` (with an edit to specify the node IP addresses or as Talos calls them in this case, endpoints).
If we run the command we'll get some output like this:
```
generating PKI and tokens
created controlplane.yaml
created worker.yaml
created talosconfig
```
Then, if we try to re-run the same command we will get a message like the following:
```
generating PKI and tokens
file "/home/angle/talos/controlplane.yaml" already exists, use --force to overwrite
```
If we do the "just go away and do it anyway" thing that it says and add `--force` it will again show the previous output.
In this process, we've wiped all the secret tokens and certificates it generated before and cannot recover them.
For a first-time installation this is barely an inconvenience, we probably do not care.
When doing this for an existing cluster, we will also need to get a new kubeconfig since the secrets that are re-generated are also relevant for the certificate that is stored in the kubeconfig to access the cluster.
That's one of the reasons that if you've had the cluster running for a couple months, this might be a bit more annoying.

## Separate secrets

The alternative is to take a more in-depth look at the documentation which will land us on a page with notes for production-level setups, specifically the section about [separating out secrets](https://www.talos.dev/v1.9/introduction/prodnotes/#separating-out-secrets).
Following the examples in that page we can run something like `talosctl gen secrets -o secrets.yaml` first and then `talosctl gen config --with-secrets secrets.yaml homecluster https://10.0.50.69:6443`.
This way, whenever we run the command to generate the configuration files (`controlplane.yaml`, `worker.yaml`, `talosconfig`) we will not also wipe the secrets.
Now, why is that process useful or even preferable?

Using this approach, the secrets can be stored separately from the configuration itself, that's the obvious part.
The less obvious part is that given the same `talosctl`, the CLI tool, we can generate the same 3 files.
Additionally, the kubeconfig that we can receive by running `talosctl kubeconfig ~/.config/kube/config --nodes 10.0.50.72 --endpoints 10.0.50.72` is not going to need to be updated even if we reinstall Talos.
You might then think, if we continually re-generate these 3 files, how can we ever permanently store configuration changes?
Putting them directly in `controlplane.yaml` and `worker.yaml` is a no-go since they'll be overwritten by a `talosctl gen config` command.
That's where patches come in.

## Patches

The `talosctl` CLI tool has a couple helpful options for applying patches when generating configuration.
Similar to having one configuration file for control-plane nodes and one for workers, the CLI flags are the same way.
There are 3 flags: `--config-patch-control-plane` which applies the patch only to control-plane nodes, `--config-patch-worker` which applies the patch only to worker nodes and `--config-patch` which applies it to both.
Using these, we can write patches and apply them as we wish to any and all of the nodes in our cluster.
All 3 of the flags accept either inline JSON patches or YAML files depending on the notation.
Now I'll switch gears a bit and discuss my own specific setup as an example.
I have 3 patches at the moment.
First, is a baseline that configures network interfaces, defines the installation disk, sets up NTP, adds kernel parameters, enables workload scheduling on the control-plane nodes and certificate rotation for the kubelet.
The other two are specific for the openebs storage system and for the metallb bare-metal loadbalancer.
It's important to note at this point that it merges the changes.
So if you want to remove something from the default configuration (such as the `node.kubernetes.io/exclude-from-external-load-balancers: ""` node label) it's not as easy as just having the key specified but being empty (for example `nodeLabels: {}`).
To generate my configuration, I can run the following:
```bash
talosctl gen config homecluster https://10.0.50.69:6443 \
	--with-examples=false \
	--with-docs=false \
	--with-secrets=secrets.yaml \
	--config-patch=@patches/01_baseline-changes-patch.yaml \
	--config-patch=@patches/02_openebs-mayastor-patch.yaml \
	--config-patch=@patches/03_metallb-patch.yaml \
	--endpoints=10.0.50.71,10.0.50.72,10.0.50.73
```
Here I've disabled documentation and examples just so the file isn't as cluttered.
The important part though is that the sensitive information is only stored in only one file which could be encrypted and put into version control.
From there, I could use the same version of the CLI tool to generate the final configuration file.
The goal is to be able to have some sort of GitOPS setup where all or most of what's needed to create the Talos configuration is stored in the same [infra repository](https://gitlab.com/insanitywholesale/infra) as everything else.
One tool that seems to fit this exact use-case is [talhelper](https://github.com/budimanjojo/talhelper) but I've not looked into it yet.

## Conclusion

I keep finding cool stuff about Talos and the homelab tinkering will continue until morale improves.
