---
title: "My dweet.io replacement ended up in production"
date: 2026-06-09T18:01:07+03:00
draft: false
tags: ["programming", "golang", "dweet"]
---

A story about [datayoinker](https://gitlab.com/insanitywholesale/datayoinker), a personal side project that I started nearly 5 years ago because I didn't like free service limits ended up in production.
I don't know when or how but I guess I'm an accomplished Go developer with code running in (someone's) production environment now.
The story is amusing to me so I want to write about it.

## Background

At some point I got interested in custom IoT stuff.
Nothing too in-depth, the usual temperature sensors and ESP32 combo.
After setting mine up I had the common dilemma of how to permanently store this data.
I was mildly aware that you could send HTTP requests (although TLS support was complicated) but most APIs I had seen in the wild and most that I'd written would only accept some specific format like JSON or XML.
I didn't want to figure out how to handle JSON in C/C++ or switch to [micropython](https://micropython.org/) so what was I to do then?
Enter [dweet.io](http://dweet.io/) (or more accurately this [web archive link of dweet.io](https://web.archive.org/web/20230209074200/https://dweet.io/)).
A wonderful little service allowing you to do GET requests to send the data and then translate the query parameters you had used to JSON when you requested it.
This was mind-blowing to me at the time.
The concept is simple, using it is simple, there is no bothersome signup and everything seems great!
I quickly tested it by changing the code on my ESP32 to send requests such as `https://dweet.io/dweet/for/bubbly-wubbly--esp32-1?room=livingroom&temperature=16.2&humidity=0.41` and then used my desktop to go to `https://dweet.io/get/dweets/for/bubbly-wubbly--esp32-1` and there was the data I had sent!

{{< highlight json >}}
{
  "this": "succeeded",
  "by": "getting",
  "the": "dweets",
  "with": [
    {
      "thing": "bubbly-wubbly--esp32-1",
      "created": "2022-05-28T19:41:17.166Z",
      "content": {
        "room": "livingroom",
        "temperature": 16.2,
        "humidity": 0.41
      }
    },
    {
      "thing": "bubbly-wubbly--esp32-1",
      "created": "2022-05-28T19:45:21.563Z",
      "content": {
        "room": "livingroom",
        "temperature": 16.1,
        "humidity": 0.40
      }
    }
  ]
}
{{< /highlight >}}

This was incredibly cool to me at the time, I could see how it was possible but I had not thought that something could work like this.
One small problem though.
I wanted to track temperature over days, weeks or months but if you read the page it says only the last 5 dweets in a 24 hour period are stored.
Also by virtue of being a service on the internet, it requires an always on and working internet connection which is something that Greek ISP have refused to provide no matter how many times I change providers or plans.
The gist is, I liked the concept but in practice it was not going to work for me.
As a newly disappointed yet determined person that can write code and have it work some of the time I knew I had to write my own.

That's how [datayoinker](https://gitlab.com/insanitywholesale/datayoinker) started.
It was a side project because I wanted my own dweet.io under my control and without the limitations.
I didn't want to straight up steal the name and the JSON schema seems very friendly but I wanted to do something different.
I named my equivalents of "dweet" and "thing", "yoink" and "topic" and brushed up on my knowledge of [Go's `strconv` package](https://pkg.go.dev/strconv) for parsing the query parameter values into variables of the correct type.
Since I was generating the `content` part with the intent to return it as JSON I thought heck why not generate it and then stuff it in a `TEXT` column in SQLite and call it a day.
The choice of SQLite was because I needed a database and that was the easiest thing in the moment.
The most "serious software engineering" part of the project was probably where I created my own error type to avoid some code duplication.
The functions handling requests were just 3, one for sending stuff, one for reading the latest message and one for reading all messages.
This was firmly in side project territory, I knew I would upload it somewhere but I never imagined it being used outside of my homelab.
I kept working on it on and off either to add functionality, add tests, do maintenance and occasionally a feature.

## Running in Prod

Around the beginning of October 2025 I was making some change to it and I was also considered replacing it with InfluxDB and Kafka or something, I don't exactly remember.
One of the features I hadn't implemented yet that dweet.io had was having an open connection and receiving data as it was sent.
This was done using chunked responses and I wasn't sure it was the best idea, maybe WebSockets or Server-Sent Events would be a bit nicer.
When I went to try out the hosted service and see how I could emulate it, I noticed it was gone!
Wondering what happened to it, I searched just for "dweet" and realized other people had noticed the same.
In fact, the blog post [Alas, the Disapperance of Dweet.io](https://www.disquisitioner.com/posts/2025/post-alas-dweet/) by David Bryant was written in May of 2025, a few months before.
In that blog post I found out about [dweet.me](https://dweet.me/).

Without reading the blog post in detail, I was relieved that maybe it was just a rename.
Out of curiosity and in order to check out how the live message API worked, I clicked the link.
Imagine my surprise when I clicked the "Get Started" button on the front page only to see the quickstart guide I had written!
My original repository is referenced at the bottom (no direct link which is odd but alright).
The URLs have been replaced which is fair enough and the hosters seem to have tried considering devices with limited or non-existent TLS support (I don't know how their setup is but the requirement for `curl -L` tells me that HTTP redirects to HTTPs which means you would need TLS support but I haven't tried it).
I hadn't received any merge requests or patches (insert arguments about how AGPLv3 requirements should be interpreted) but this fork seems to have done one of my TODOs which was about deleting data periodically.
This is a good idea, even necessary I would say, if you run it as a publicly available service but for my personal use it wasn't needed which is why I procrastinated adding it.
Hilariously this also re-introduces the problem of limits on the publicly available free service which is why I wrote [datayoinker](https://gitlab.com/insanitywholesale/datayoinker) in the first place.
I had mixed feelings about it, I did write the software for people to use and I was glad someone was getting mileage out of it (a bit miffed about the non-clickable link and that being the only mention of the underlying software).
To be clear, I want *more* people to use it so I want them to be able to find the repository and run it themselves.
My personal (vain?) desire for recognition is covered by the reference as-is.
Anyway, it was a surprise and it did lead me to a couple of questions:

>Q: Am I now officially a Go developer?
>
>A: My code (or at least part of it) is technically running in production.

We'll call that a maybe. I don't know that anyone will hire me based on this.

>Q: Is my side-project load-bearing for someone else?
>
>A: I could cause upgrade problems for someone if I changed the database schema without a migration.

Another maybe. I don't know how committed anyone is to running this in perpetuity but I will do my best to not break stuff.

>Q: Should I contact the team hosting it?
>
>A: I should let them know when I've done maintenance or added a new feature so it seems worth it.

I'll sleep on that for a bit, I don't want to bother strangers doing their best to run a free of charge service on the open internet.

Now that the weird 3-person dialogue with me, myself and I is over I want to give a brief guide for how to run the software yourself.

## Datayoinker's first release

A few days ago I fixed up the goreleaser config in the repository and released [datayoinker version 0.0.1](https://gitlab.com/insanitywholesale/datayoinker/-/releases/0.0.1).
I can't say that I'll commit any more time to work on it since I do have a full-time job that keeps me busy enough most days but it's a neat project that I'd like to keep developing.
To facilitate more people being able to use it, I've made [the README](https://gitlab.com/insanitywholesale/datayoinker/-/blob/main/README.md?ref_type=heads) a little nicer with examples and such.
There are 20 binaries compiled already for platform and architecture combinations I thought would be useful as well as a multi-architecture (`linux/amd64` and `linux/arm64`) Docker image.
If you feel like the software would be useful to you, dowload a binary or the Docker image and give it a try!
There is no user creation or database configuration.
All that's needed is 2 files, the binary of the application and the database file that gets automatically created on startup if it doesn't exist already.

Since the release, I've done a bit of refactoring to make the code about 70 lines shorter and less busy to the eyes but nothing major yet.
I have not yet improved the frontpage of the application or the quickstart but I will try to get to it at some point although frontend web design is not my passion.
There are no urgent plans to add automated deletion because like most people that would self-host it I don't have anything that produces that much data.
Going back to [David Bryant's post](https://www.disquisitioner.com/posts/2025/post-alas-dweet/), I thought that maybe I should add API enpoints that are the same as dweet.io so people have an easier time migrating.
With the original service being down, I don't have a working example to compare to but I'd like to try it out maybe by using the original client libraries as a conformance test suite.
This summer seems pretty busy at the moment but I will see if I get some free time for this.
If someone tries this and has any feedback or suggestions, feel free to reach me on [bluesky](https://bsky.app/profile/inherently.bsky.social).

## Conclusion

Yoinking implies pulling but the service doesn't pull data, this might be a naming mistake in hindsight.
I did get pulled into a rabbithole and ended up writing some software about 4 years ago and it was a nice surprise that someone else got some use out of it.
If you have IoT projects running at home, give it a try.
