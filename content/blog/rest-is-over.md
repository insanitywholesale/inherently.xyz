---
title: "REST Is Over"
date: 2021-04-04T17:33:02+03:00
draft: false
tags: ["programming", "opinion", "api", "grpc", "rest"]
---

## Web APIs are terrible
After watching a talk a few months back about REST vs GraphQL and the history of APIs, I agreed with the speaker that the API is supposed to be a way of communication, a language of sorts.
In programming languages this codified way of communication is enforced by the compiler or the interpreter or the runtime.
If you write invalid code in the programming language of your choosing, it won't work.
Something or other will complain or break and prevent you from miscommunicating.
This got me wondering APIs especially web ones are so bad.

## RESTing comfortably
With the introduction of what we call REST nowadays, basically JSON over HTTP, it's all too common for application to use this mode of communication.
How this is enforced in practice is very variable though.
From different path schemes, to the same HTTP verbs used for different purposes, to (invariably bad) ways to communicate from machine to machine what the API is, it's all up in the air.
Most fairly complex things that have a REST API, don't even expect you to use them by directly interacting with it but instead use client libraries.
This has been going on for about a decade or two and it seems things are changing.
Some thought that GraphQL would be the end of that and it's a pretty good step up but adoption is nowhere near as high.
In general REST is the assumed default way to interact with something programmatically.
Should it be though? Is GraphQL the best replacement we've got? I don't think so.

## gRPCee what I did there
A somewhat recent thing called gRPC started picking up steam.
Talks about it, articles about it, large software projects using it but not really prominent on the web.
With this nifty little thing after writing a file that describes what your program does, you can generate some ready to use code, write the logic and `grpc.Serve()` to the moon.
Even better, anyone wanting to write a client in any of the many supported languages can generate the boilerplate for a client from the same definition file and start calling the functions of the server really easily.
I'm being a bit simplistic for the sake of brevity but it's really cool, trust me. It's also really fast.
Alright, it's better than freshly baked bread apparently so why is it not used on the web?
Cause it's only HTTP/2 and the support for that is pretty limited.
Fear not though, we're going to circle back to our crusty old frenemy, REST.

Support for REST is widespread and there is a webdev in every city block ready to POST some JSON to your endpoint.
So we can't immediately get rid of the kludgy wart but what about giving pixel pushers some REST while service to service communication is improved?
You see, since definitions exist for what the service sends and receives, the types of all the things being passed around, it's quite easy to use some simple annotations to auto-generate a REST API.
This doesn't 100% fix the problems that exist but it does smooth over some parts of it.
Okay so that's it? Not just that, since the API is standardized we can even auto-generate documentation for it!
OpenAPI (formerly Swagger) docs can be easily generated and served to potential downstream users of the API.
Brilliant I think.

## Conclusions
Over the past few months I've been reading a lot about gRPC, grpc-gateway, different ideas and implementations, trying out quite a few of them but I've yet to see one that makes me super excited and go "Aha! this is The One" or whatever.
I could do a link dump of about 100-150 tabs that I have open but that would be tiring and essentially do nothing to help.
Currently I've been trying to decide among 2-3 options for how a service should be structured and such but I'm still testing out prototypes, haven't reached any conclusions.
However, I hope this was a semi-educational read and got you a bit interested in the ecosystem.
That's all for now, I hope you enjoyed reading.

### pardon me
~~check out the [tutorials]({{< ref "tutorials" >}}) section for my Go REST API Part 2 coming soon~~
sorry, I had to :^)
