---
title: "Droning On"
date: 2021-05-01T18:54:59+03:00
draft: false
tags: ["homelab", "sysadmin", "devops", "kubernetes", "drone", "continuous integration"]
---

## Previous relevant post
The post exploring my choice of a continuous deployment tool was covered [here]({{< ref "blog/fluxing-my-cluster">}}) if you're interested, this post is about continuous integration.

## Intro
I described previously how the deployment of applications is automated in my homelab but didn't touch upon how I test my own code.
The topic came up when I started trying to simulate a development pipeline who's first step after committing code is to be run through the continuous integration system.
What should that system be though?
In this post, I'll take you through the things I tried first and then why I went with [drone](https://www.drone.io/) in the end.

## Choose a Fighter
My quest is to ultimately end up with the skills to set up kubernetes so that it can be deployed to everything from a DIY NAS and a stack of NUCs to a warehouse full of servers backed by distributed storage.
I'm obviously more towards the first camp so that's where my journey is at.
With that said, my goal is to have software small and lightweight enough that it can run on the former setup easily so that there can be multiple instances of it in the latter form.
The current mental model I have is developer organization with not much more than 3 NUCs + 1 NAS per team without losing the ability for continuous integration and continuous deployment.
Therefore the landscape needs to be explored and the obvious titan of the old world is [jenkins](https://www.jenkins.io/) with many newcomers eager to take its place.
The obvious caveats still apply, it must be open-source, able to be self-hosted, support for gitea is needed and being able to run well on kubernetes is a foregone conclusion.

### Jenkins
It should need no introduction, most developers are familiar with the trusty crusty old butler software.
[Jenkins](https://www.jenkins.io/) is probably one of the most prominent pieces of CI/CD software that was pushed to the forefront when the push for more automation and increased code quality really happened.
Sadly there are a few reasons that annoyed me from the get-go.
First, the unlocking procedure requires you to `kubectl logs <podname>` in order to find the unlock key which I understand but nonetheless find annoying.
Second, the `Jenkinsfile` has its own domain-specific language (DSL for short) that I find unappealing even though you won't catch me praising YAML's lack of curly braces.
I begrudgingly went though it and wrote a `Jenkinsfile` to give it a fair chance but it wasn't a nice experience.
Next, a single instance uses too much ram to the point that it can barely fit in my k3s VMs which use 2.5GB of ram each together with other software.
This is an issue because I like running at least 2 instances of most applications to be sure that everything works correctly when scaling up.
Last but not least, it's a 2-in-1 solution which I don't find appealing as far as architecture and since I was planning to find a standalone piece of software to do CI and another one to handle CD, it was a hard sell from the start.
As a redeeming quality it has an official kubernetes pipeline plugin which is nice so they've at least put thought into this use case.
Ultimately it wasn't the right fit for me so it was time to move on.

### Drone
While pondering this I remembered an old post from one of the blogs I read, specifically [this one](https://christine.website/blog/drone-kubernetes-cd-2020-07-10).
I said what the hell, why not and started looking its website.
[Drone](https://www.drone.io/) is a very nice and simple continuous integration tool.
From the start it seemed like it would be a good pick but you never know until you try.
I wrote some kubernetes manifests, got angry until I got them to work and a half hour later it was hooked up to my local gitea instance and ready to use.
I added a `.drone.yml` to one of my repos, pushed the change, activated the repo from the drone dashboard, made another change to the source code, pushed it and waited to see what happened.
Instantly drone received the webhook event and got to work.
The dashboard is pretty simple (and sadly lacks a dark mode) so you just hit the thing you want to look at, click on the build and see it happen.
It supports different things running at the same time like databases if you want your tests to include that which can be run either as what drone calls `services` aka run in the background from the beginning or if you want an ordered dependency you can use detached steps which is especially useful in microservices.
My only real complaint aside from the lack of dark mode is the inability to trigger a build manually without pushing but that's only an issue when you first activate a repository inside drone's dashboard.
All in all, it has been a joy to use, most of the projects I am currently developing have a `.drone.yml` and get built at least 3 times a day when gitea mirrors the gitlab or github repo they're mainly hosted at.

## Conclusion
This wasn't as big of a journey as finding a continuous development tool because really I only found the two aforementioned options that had the basics I was looking for and one of them didn't really fit the bill.
I'm not huge into software development, it's mostly a hobby for me as might be obvious by now, since my main concern is infrastructure-related stuff.
With that said it's useful to have the skills to build an application that can communicate with the kubernets api to automate something or write an ansible module and most of all it allows me to see the developer perspective.
I haven't started looking into [SOPS](https://github.com/mozilla/sops) or [renovate bot](https://renovatebot.com/) or the [k3s upgrade controller](https://github.com/rancher/system-upgrade-controller) or [velero](https://velero.io) but I hope to get the chance to do so in the future.
Thank you for reading, I hope you enjoyed it and maybe learned something.
