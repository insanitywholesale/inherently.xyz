---
title: "Fluxing My Cluster"
date: 2021-04-17T17:24:22+03:00
draft: false
tags: ["homelab", "sysadmin", "devops", "kubernetes", "flux", "continuous deployment"]
---

## Intro
It's no secret that I'm a fan of automation and making life easier (even if I made it harder in the first place).
One of the issues I've been having in my homelab is dealing with deploying stuff to kubernetes.
Initially I wanted to just add a plugin to [drone](https://www.drone.io/) and be done with it.
However, that didn't really pan out which ended up being to my benefit since I discovered [flux](https://toolkit.fluxcd.io/).

## The problem
The cluster in its current state is a little sad because I end up doing too many things manually.
Whenever something changes it's time to bring out ye old `kubectl apply -f` in a local clone of the repo and that doesn't spark joy.
This was obviously bad form and couldn't continue.
What you also have to keep in mind is that I've chosen a 3rd-party storage plugin, [democratic-csi]() and assume it's the default storageclass in the cluster.
This means that on a new cluster it's required that before anything else, that one is added as a storageclass and set as default and `local-path` is removed from being a default.
After that, the applications can be deployed which includes a mix of stuff I've written for the purposes of testing as well as 3rd-party software.
Now that the stage has been set, let's see what I tried

## Solutions

### Drone CI plugin
Initially the idea was that since I've alrady solved this for code using drone for CI (this will be discussed in a later post), I could just use a plugin and be done.
However, my experience with writing helm charts is limited and the only official plugin for deploying to kubernetes is for helm charts, not kubernetes manifests.
Furthermore, as I mentioned previously, not all software deployed on the cluster is something that I have written so even if there was an official kubernetes manifest plugin it wouldn't cover 3rd-party software.
At this point, I was thinking of finding some all-inclusive CI/CD software that would cover everything I wanted to do.
It took no more than 10 seconds of thinking to realize that I was looking for non-modular software and discard that idea.

### Standalone Continuous Delivery
This was the obvious choice but the software in this category is plentiful.
The main competitors were [flux](https://toolkit.fluxcd.io/), [argo](https://argoproj.github.io/projects/argo-cd/) and [tekton](https://tekton.dev/).
Their designs differ quite a bit so there is going to be quite a bit of opinion in the following analysis so just keep that in mind.
The few things they had in common were that they were all advertised as cloud-native with support for kubernetes, had a cli and were written in Go.

#### ArgoCD
I started with argo because one of the people that wrote a really good blog post on using kubernetes at home mentioned that they use it so I thought I'd try it first.
The installation process required a massive yaml file that you just `curl | kubectl apply -f` which I wasn't a big fan of but alright whatever.
It also had a weird unlock procedure like jenkins where you have to find a token generated at runtime to unlock it but that's okay, just an one-time setup thing.
After spending a couple evenings with it, I wasn't satisfied with the experience.
The docs weren't really good at explaining all the argo custom resources and getting a basic single-pod application running took me more than 2 hours.
It was doable but this was going to be something I had to do for every application running on my cluster and the prospect didn't seem appealing.
I'm sure with more time I could maybe become more familiar and eventually warm up to it however first impressions were bad so I decided to move on.

#### Tekton
Tekton's marketing was interesting so I took a look at it next.
It seemed to be easier to set up and a couple random blog posts seemed to praise it so I downloaded another massive installation yaml which the guide told me to just `kubectl apply -f` which is okay I guess.
I spent a few hours with it and it became clear you basically had to use it both for CI and CD so I put it to the side and moved on.

#### Flux
So why did I mention this one first but try it last?
A few reasons.
While researching, the v1 -> v2 development effort was going on and v2 didn't have a lot of features but v1 was being phased out so I didn't know if I should spend time learning v1 while v2 was coming along or if it's worth jumping into alpha/beta stage software to avoid using legacy versions.
By the time I did get around to it though v2 was clearly the way forward.
Not only was it officially endorsed but among people that self-host, it was already the way to go 6-12 months ago.
The docs were pretty clear, the cli was cross-platform and could be installed on a Raspberry Pi (something that argo at the time didn't have available) and the examples worked.
In an evening I had learned basically everything I needed to in order to just drop it in, generate the flux CRDs for my existing kubernetes manifests as well as helm charts and be up and running.
The only issue I had, probably just a pet peeve of mine, was that the repo it creates on github is private by default and my goal is to have everything public and also secure (not there yet) but whatever.
Flux v2 also mentioned as the gitops toolkit is made up of several different parts that have a specific purpose which is something I certainly appreciate.
All in all, I think I'm going to stick with flux but you never know how homelab things will end up.

## Conclusion
Flux is a really great project and I've enjoyed using it so far.
The problem of continuous delivery has been solved for me and I recommend checking out if you're in a similar position.
Next up, I'm going to look at [renovate bot](https://renovatebot.com/) for automating image updates, [SOPS](https://github.com/mozilla/sops) for secret management (which [flux supports](https://toolkit.fluxcd.io/guides/mozilla-sops/) and [an upgrade controller](https://github.com/rancher/system-upgrade-controller)) to further help automate operations.
Thank you for reading, I hope you enjoyed it and maybe learned something.
