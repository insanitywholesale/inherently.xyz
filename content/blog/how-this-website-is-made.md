---
title: "How This Website Is Made"
date: 2021-11-20T20:56:19+02:00
draft: false
tags: ["programming", "sysadmin", "web", "hugo"]
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
Hugo is a static site generator meaning that it creates the files required for the site once and that's it, the site is not dynamically put together on the client.
As the author, you mostly write markdown files that are turned into html at build time and then you can put those html files anywhere you'd like.
This is what the site uses to this day and you find the source code for it [here](https://gitlab.com/insanitywholesale/inheresite-hugo).

### Transitioning
The real work started when I decided I'd make my own theme too.
I didn't just have to move my content and page structure to it but write some nice fresh CSS too since I decided I've had enough of bootstrap.

#### Directory Structure
The first steps was examining the [directory structure](https://gohugo.io/getting-started/directory-structure/)  and finding the most low level template file which is `layouts/_default/baseof.html` and making my way up.
Inside there I defined the very basics of what the HTML would look like, imported my CSS file which at this point had about 5 lines in it and moved on to the other fundamental pages.
These are `layouts/_default/single.html` and `layouts/_default/list.html`, the former being about a "one of it's kind" page and the latter being an aggregation.
The example here is a blog post and the list of all the blog posts.
They are based on `baseof.html` and in my case are very short, consisting only of the barebones required to implement these types of pages.
This is because they are overwritten by category-specific `single.html` and `list.html` which is how I make blog posts have a table of contents and how I make the `blog` section look different than the `tutorials` section.

#### Layouts
Speaking of sections, the first thing I got up and running was the `blog` since that was the easiest one with lots of documentation and examples.
The second priority was the front page which turned out to be a little bit more complicated.
You put the content for it inside `content/_index.md` and the layout-related stuff inside `layouts/index.html`.
In hindsight it's fairly intuitive but it took a few minutes of digging when I was less familiar.
For each sub-category you can basically include no layout files in which case the `list.html` and `single.html` from `layouts/_default` will be used or you can write ones that will override them.
As an example, in `layouts/tutorials` I have both a `list.html` and a `single.html` to build the tutorial-related pages in their own way.

Layouts are pretty cool and probably my favorite thing is partial layouts.
These allow you to put a snippet in a file, let's say `footer.html` and then include it using `{{ partial "footer" . }}` in another template.
One other example is the contact form, I just made a `layouts/contact/list.html` that has the line `{{ partial "comments.html" . }}`  and this way I can keep the template cleaner and allow reusing that comment submission form elsewhere too.
So I just went around creating my categories, writing specific list or single templates for them if required and throwing some pieces of reusable code in partial layout templates.

#### CSS
The most involved part was by far the CSS.
I have to say that if it's not obvious by now I'm not a "frontend person" per se, I just want something that looks clean, fast and readable.
As a disclaimer, I'm not a fan of the size of the fonts which are by far the biggest element right now but I'm a huge fan of the fira font family (with the exception of fira code cause I hate ligatures) but they work well enough.
It took the majority of the time and had the most updates, tweaks and fixes by far compared to anything else.
Essentially nothing from the original CSS is the same except the colors which was a long process but a necessary one to get where I wanted to be.
In the end I'm satisfied with it, I think it looks fairly unique and serves its purpose well while coming in at under 200 lines (it is way less in reality but the number balloons up because of the way I format the code).

#### Docker
This time I went with a custom docker image so I could have more control and no filesystem bind mounts.
The main problem is that the hugo team does not publish an official docker image so I had to use the following to get hugo installed in the container in order to generate the site (most current Dockerfile is in [the git repository](https://gitlab.com/insanitywholesale/inheresite-hugo/-/blob/master/Dockerfile), check there first before copying):

```dockerfile
FROM golang:1.16 as buildsite
ENV CGO_ENABLED 0
WORKDIR /go/src
RUN git clone https://github.com/gohugoio/hugo.git
WORKDIR /go/src/hugo
RUN go install -v
WORKDIR /go/src/inheresite-hugo
COPY . .
RUN hugo

FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/
COPY --from=buildsite /go/src/inheresite-hugo/public /usr/share/nginx/html
```

This means I compile hugo every time I want to upload a post but it goes fairly fast and gives a bit of time to reflect on what I've written.
If this is not for you, use either an ubuntu image and install it with apt if you don't need the latest features or an arch one if you need the latest release for some reason.
Using third-party images is a last resort but those are technically also usable for this purpose however I'd advise against using images from random people.

### Impressions
After a long while with hugo I think I'll be sticking with it.
It allows for some pretty clean code, I'm partial to Go templating and it has served me well.
I'd like to look into some small improvements such as merging tutorials into blog and just displaying them in a different way but that's a topic for another day.
The full server-side syntax highlighting is awesome too, I thought I'd need to cave and use some javascript thing to do it but thankfully it worked out great and I found a code theme that matches the rest of the site.
If you want to get started with it, just make sure you know some basic HTML and have some patience, the rest can be figured out in an evening.

## Conclusion
The site you're currently looking at has been a while in the making and there are still a couple items on my `TODO.md` for it but I'm happy enough with it for now.
You might want to check out [the comment microservice](https://github.com/insanitywholesale/gommenter) I wrote for use with the comment form mentioned a bit above, it's far from perfect but it gets the job done.
Thank you for reading this, I hope you enjoyed it and maybe even learned something.
