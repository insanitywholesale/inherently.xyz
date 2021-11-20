---
title: "How This Website Is Made"
date: 2021-11-20T20:56:19+02:00
draft: true
tags: [""]
---

## Intro
A significant part of having my own site is the way it's made behind the scenes.
This has changed in a couple different ways for the duration of its existence and in this post I'll try to explain how and why.

## Beginning
When I first bought `inherently.xyz` to host my own website I wanted my site to be built in the way that I'd like other sites to be built.
The main requirements were:
- a theme that was mine
- basically no javascript
- nothing loading from third-party places
- code that is easy to understand
- readable in the devtools
- reasonably small and fast
- able to be read on a lot of devices and browsers
- over the top way to host it
I don't think I have a repository where I developed it but [this is an archive](https://gitlab.com/insanitywholesale/distrowatch) of some version of it.
I'll retell the story of its existence so you don't have to look at the source but it's there if you want to take a look.

### Evaluation
In my humble opinion I did fairly well to cover the requirements I had but not as well as I could have.
However not all was great. For one, I had used bootstrap, the CSS framework, to make the site.
Because I used the navbar hamburger/button/dropdown thing it required some javascript/jquery which was unfortunate.
It was my goal to get rid of this but from reading a github issue about it the team behind bootstrap did not feel like providing that functionality through a CSS trick was something they were willing to do.

The theme was mostly mine outside of boostrap and it was adapted from someone else's CSS colorscheme.
As for the code itself, every page consisted of hand-written HTML so that part was easy to read but the minified bootstrap files, aside from being pretty damn big, were unreadable.
At least the bootstrap files were hosted on my own server and no third-party anything loading so I can check that off the list.
Additionally, to make the site I had created a file called `base.html` containing the basic template of a page which I would manually copy to create a new page and then rsync the files from my computer to the server.
Surprisingly enough, this worked pretty well although changing code that touched multiple pages like the navigation was somewhat cumbersome.
Reading the website through a lesser known web browser like `netsurf`, `surf` or any text-mode web browser was possible so that requirement was basically 100% satisfied.

Since the beginning of this site I've been using docker-compose to host it.
For this iteration I was using a simple nginx image and mapping the directory on the filesystem to `/usr/share/nginx/html` inside the container.
Traefik was running in front of it acting as a reverse proxy and to support https.
Overkill for a site that has handwritten HTML? Check.

## Improvements
There was quite a bit of way to go as you can gather from the above.
The main pain points were the existence of javascript causing the navigation dropdown to not work on mobile when javascript was disabled, the performance metrics related to using bootstrap in general, dependency on bootstrap and lack of major customization from me.
The raw HTML workflow was mildly annoying but it never stopped me from writing anything.

### Solutions
I spent quite a long time trying to find a workaround for the nav dropdown and eventually stumbled into a solution in a post I can't find anymore, I'll update this if I do.
That worked fine enough and allowed me to get rid of the jquery dependency that, funnily enough, had a vulnerability announced about it while I was rewriting my nav code.
Bootstrap was also slowing down everything according to all benchmarks I ran.

This was all fairly fine for quite a while.
I kept working on the site, writing stuff and having my own little space on the internet.
The curse of being into tech and knowing how to make a website even as basic as this was that I wanted to rewrite it.
That's when I started exploring and found out about [hugo](https://gohugo.io), a fast static site generator (SSG for short) written in Go.
Given that I was interested in Go at the time of this rewrite and that I knew how the templates worked more or less I decided to give it a try.

## Hugo
My first idea was to just port it to hugo and then improve it and quickly realized what a mistake that would be.
Why do one thing you've never done before if you can do two, right?
