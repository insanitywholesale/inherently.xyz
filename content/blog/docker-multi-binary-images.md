---
title: "Docker Multi-Binary Images"
date: 2021-08-02T17:43:30+03:00
draft: false
tags: ["docker", "devops", "linux"]
---

## Problems in deploying distributed applications
If you read my background in the front page, you know I'm not a prolific programmer by any definition.
This isn't going to be a gigantic revalation and if you've worked with deploying your own applications to kubernetes you'll already know most of the following things.
With that said, what are the problems with deploying a distributed application?
I was tinkering with [gifinator](https://gitlab.com/insanitywholesale/gifinator) and while writing the kubernetes manifests I realized there was a problem.
A few bugs required multi-service re-deployments.
Let's say there was something affecting the render service and the gifcreator worker service.
I could rebuild 2 new docker images, push them to the local image repository, update the version in their respective manifests and apply the changes.
The issue is that after doing it once or twice it became really annoying when wanting to roll back to check the previous behavior.
The more this cycle went on, I had to keep track of a set of 4 different versions which quickly became unmanageable.

## Lightbulb moment
That's when the obvious dawned on me, the upstream kubernetes manifests all used the same image somehow.
I quickly opened them up and checked to see they were redefining the container's `CMD` directive!
In fact the actual Dockerfile did not even have a `CMD` nor `ENTRYPOINT` defined.
The code was built, the binaries were copied to the second stage and the final image was shipped.
Using this method the final image is as small as possible without needing 4 separate ones.

## How do
It's pretty easy to do this so let's take a look at the Dockerfile as well as the kubernetes manifests.

### Dockerfile
This specific Dockerfile is available [on gitlab](https://gitlab.com/insanitywholesale/gifinator/-/blob/master/Dockerfile) for those interested but I'll paste it here for ease:
```dockerfile
# build stage
FROM golang:1.16 as build

ENV CGO_ENABLED 0
ENV GOOS linux
ENV GOARCH amd64
ENV GO111MODULE on

WORKDIR /go/src/gifinator
COPY . .

WORKDIR /go/src/gifinator/render
RUN go get -v
RUN go vet -v
RUN go install -v

WORKDIR /go/src/gifinator/gifcreator
RUN go get -v
RUN go vet -v
RUN go install -v

WORKDIR /go/src/gifinator/frontend
RUN go get -v
RUN go vet -v
RUN make installwithvars

# run stage
FROM busybox as run
RUN mkdir /tmp/objcache
RUN mkdir /tmp/scene
COPY --from=build /go/bin/render /render
COPY --from=build /go/bin/gifcreator /gifcreator
COPY --from=build /go/bin/frontend /frontend
COPY ./gifcreator/scene /tmp/scene
COPY ./frontend/templates /templates
ENV FRONTEND_TEMPLATES_DIR=/templates
```
First up we set some basic environment variables and copy the code into the building environment.
Then one by one the services are compiled and installed into the build stage image.
Following that, in the run stage the needed directories are created, the binaries are copied over, assets are also copied over and a final environment variable is set.
There is no `CMD` or `ENTRYPOINT` as you can see, this will probably result in the inability to just `docker run -p externalport:internalport imagename` but the tradeoff is well worth it.

### Kubernetes deployment manifests
With the Dockerfle out of the way, let's look at the way these images are deployed.
The primary way I run containers is through kubernetes so we'll be looking at kubernetes manifests.
Same as the Dockerfile you can find the source for these manifests on gitlab, I'll be linking each one.
[kube/manifests/gifinator/render/deployment.yml](https://gitlab.com/insanitywholesale/infra/-/blob/master/kube/manifests/gifinator/render/deployment.yml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: render
  namespace: gifinator
  labels:
    app: render
spec:
  replicas: 1
  selector:
    matchLabels:
      app: render
  template:
    metadata:
      labels:
        app: render
    spec:
      containers:
      - name: render
        image: inherently/gifinator:0.0.5
        command: ["/render"]
#the rest of the file is omitted
```
[kube/manifests/gifinator/gifcreator-server/deployment.yml](https://gitlab.com/insanitywholesale/infra/-/blob/master/kube/manifests/gifinator/gifcreator-server/deployment.yml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gifcreator-server
  namespace: gifinator
  labels:
    app: gifcreator-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gifcreator-server
  template:
    metadata:
      labels:
        app: gifcreator-server
    spec:
      containers:
      - name: gifcreator-server
        image: inherently/gifinator:0.0.5
        command: ["/gifcreator"]
#the rest of the file is omitted
```
[kube/manifests/gifinator/gifcreator-worker/deployment.yml](https://gitlab.com/insanitywholesale/infra/-/blob/master/kube/manifests/gifinator/gifcreator-worker/deployment.yml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gifcreator-worker
  namespace: gifinator
  labels:
    app: gifcreator-worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gifcreator-worker
  template:
    metadata:
      labels:
        app: gifcreator-worker
    spec:
      containers:
      - name: gifcreator-worker
        image: inherently/gifinator:0.0.5
        command: ["/gifcreator", "-worker"]
#the rest of the file is omitted
```
[kube/manifests/gifinator/frontend/deployment.yml](https://gitlab.com/insanitywholesale/infra/-/blob/master/kube/manifests/gifinator/frontend/deployment.yml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: gifinator
  labels:
    app: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: inherently/gifinator:0.0.5
        command: ["/frontend"]
#the rest of the file is omitted
```
Here are 4 different services, all easily using the same image.
Just by redifining the command it's easy to simplify the development process by a quite a lot.
It's worth noting that I've only shown the deployment manifests since the other ones don't have anything to do with the container image used.

## Conclusion
This is a short post mostly made up of code snippets but I hope you learned something and can improve your workflow with distributed microservice applications.
