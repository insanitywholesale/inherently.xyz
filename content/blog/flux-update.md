---
title: "Flux Update"
date: 2021-08-25T00:44:34+03:00
draft: false
tags: ["homelab", "sysadmin", "devops", "kubernetes", "flux", "continuous deployment"]
---

I wrote about my journey of choosing a continuous deployment tool and why I ultimately ended up using [flux](https://toolkit.fluxcd.io/) for my homelab [in this post]({{< ref "blog/fluxing-my-cluster" >}}).
It took quite a bit of reasearch and if you're in a similar position as I was it might prove to be helpful.

## Long(ish)-term experience
I've been using it for about 5 months now, the first post was written about one month of use.
At that point I had been tinkering with it and attempting to get all the stuff I wanted to be deployed by it.
Some things were simple, others not so straight-forward.

### Successes

#### Deploying raw manifest applications
Deploying raw kubernetes manifests was really easy.
Since I'm somewhat on the fence about Helm, I prefer using normal kubernetes manifests where possible.
This meant that for my use case mostly everything was smooth sailing after figuring out how to generate a kustomization yaml using the command-line tool.

#### Command-line tool
Speaking of that, flux has a command-line tool to interact with the controllers running inside the cluster.
It's also the way you can initialize a repository to be used as the place for flux files to be stored.
It can also be used to install flux to the cluster if the repository already exists.

#### Upgrading
When a new version of flux comes out, you can upgrade and it will carry over to the cluster.
It's really easy, it just upgrades its own files so when those are committed it will pull in the new version of the controllers.

### Trouble

#### Aggregation yaml
For starters here is a minor one that took way too long to diagnose.
I forget exactly what this is called but essentially it is a yaml file says run deal with the listed resources.
Imagine the following directory contents:

```yaml
drwxrwxr-x 4 angle angle 4,0K Αυγ  25 01:23 .
drwxrwxr-x 5 angle angle 4,0K Ιουλ 21 03:42 ..
drwxrwxr-x 2 angle angle 4,0K Αυγ  13 15:55 helmrepos
-rw-rw-r-- 1 angle angle  219 Ιουλ 21 03:20 infra-source.yml
-rw-rw-r-- 1 angle angle  126 Αυγ  12 11:45 kustomization.yaml
drwxrwxr-x 2 angle angle 4,0K Αυγ  13 15:56 storage
```

The `kustomization.yaml` file is as follows:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - infra-source.yml
  - helmrepos
  - storage
```

So it's a way to more easily include stuff.
The issue I had is that I named the file `kustomization.yml` instead of `kustomization.yaml` which for some reason isn't supported.
I believe this is a bug and not intended behavior but it was still frustrating to find and fix.

#### Logs
Now on to more substantial issues.
While troubleshooting I got a bit frustrated with how flux displays errors.
The messages are fairly non-descript and there isn't a lot of guidance for how to fix them.

## Conclusion
Despite a couple rough edges, flux has been working incredibly well.
Even before I got it fully functioning, it was amazing to be able to just install it to a newly creted cluster and have all my applications running just like that.
It's almost magical and I've been enjoying it quite a lot.
If you aren't using a continuous deployment tool, feel free to give [flux](https://toolkit.fluxcd.io/) a try or read the previous post to learn about some other options
