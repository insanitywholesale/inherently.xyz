---
title: "Beyond Docker"
date: FILL--THIS--IN
tags: ["tutorial", "docker"]
draft: true
---

# Docker and beyond

## Preamble

On the first part I only talked about docker and functionality included with it by default. This time we are going to look at a few extras. The list includes but is not limited to

- docker-compose since it's often the next step after standalone docker
- a couple tips for Dockerfiles like being extra paranoid about the base image used and how to make sure the thing inside the container is running and listening to requests
- setting up a quick and dirty nextcloud + gitea + simple test site and using the traefik to reverse proxy traffic to all of them
- having a local docker registry to be less reliant on an always-on internet connection

Sounds exciting, right? Let's get started then

## Prerequisites

- MUST :
	+ Have Linux installed
	- Have Docker installed
	- Read the first part
- OPTIONAL:
	- Some basic knowledge of YAML
	- PfSense with DNS Forwarder as the DNS server of the network

## Docker-compose

We didn't delve into real multi-container applications last time and that was intentional. The simple site example, reactjs website and golang backend were all self-contained and ran on their own but it's fairly rare to have something like that running. Many selfhosting-oriented images out there might have an embedded sqlite database suitable for single-user or low use but provide a way to connect to a real database, like mariadb or postgres, when the use exceeds the basic requirements. How would one go about that you might be asking. Write a nice shell script to handle starting/stopping/restarting everything in the right order? That was my first thought too but the answer is docker-compose. Here is where we enter the concept of a service, a collection of all images and configuration that a complete application needs to run. This might include a client component, a server component, a database (or two with one being a cache) maybe even multiple server components. All of this can be done in a single YAML file, no long `docker run` commands, and can be used in quite a few different ways.

### Installation

First of all, how do we get that. Following the first-glance upstream documentation and suggestions it might seem like you install it like docker but I suggest a different route. Of course, first priority is through the repository (if applicable). If you can't, there is a script in the alternative installation options that is placed in ``/usr/local/bin` or wherever else in`$PATH` we deem appropriate that in turn downloads docker-compose as a container. This is by far my favorite way of getting it and I recommend you give it a try. However, you are welcome to ignore my advice and use the default method for your distro that is mentioned in the installation section of docker's docs. After it's installed we can jump into the fun.

### First Use

#### Writing the docker-compose file

For our first multi-container deployment, let's try [gitea](https://docs.gitea.io/en-us/install-with-docker/ "Gitea Install with Docker") since it already has pretty good examples. The first ingredient we need is a file named `docker-compose.yaml` or `docker-compose.yml` if we wish it to be automatically recognized by the `docker-compose` command the same way a file named `Dockerfile` is recognized by `docker build`. However, an argument can be give to the `-f` flag in order to specify a different file if that's what we wanted to do. For now, we open our favorite editor and start writing.  
First up, we need to specify what version we're using at the very top of the file. This will determine what features we have access to. The latest major version is 3 so let's go with that:

```
version: "3"
```

It needs to be provided as a string which is why it's surrounded by double quotes. Next up we specify our services, meaning the declaration block for the individual containers and their settings:

```
version: "3"

  services:
```

Please note the whitespace indentation, this is how YAML is written. After telling docker-compose that we're about to define our services, let's actually define one:

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart: always
```

Which means the service is named `server` which uses the `gitea/gitea` image and should always be restarted. Below it we can fill some environment variables:

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=1000
        - USER_GID=1000
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=gitea
        - DB_USER=gitea
        - DB_PASSWD=gitea
```

The lines below `environment` that start with a dash are items of a list in YAML, in this case environment variable and their values. The example above has the disadvantage of possibly including passwords and access keys or tokens in this file so you can't store it in a public git repository. We'll take a look at how to remedy this later on and we'll assume it's fine for now.

Let's move on to specifying the networks and volumes this container will use (declarations for networks and volumes will be covered later, don't worry). First a mount point for data and two for sourcing the time from the host system (the `:ro` means read only so don't worry about your host files being overwritten or corrupted). This is what the file looks like after those additions:

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=1000
        - USER_GID=1000
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=gitea
        - DB_USER=gitea
        - DB_PASSWD=gitea
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
```

Quite a bit nicer and easier to read than the multiple command-line declarations I think. Now that it's hooked up to a network, it needs at least one port to expose its web interface on (port 3000) and there is also the ability to ssh into it (using port 22 which is the standard port for it). Here is how ports are mapped in a docker-compose file:

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=1000
        - USER_GID=1000
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=gitea
        - DB_USER=gitea
        - DB_PASSWD=gitea
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
      ports:
        - "3000:3000"
        - "222:22"
```

The above covers the gitea server part but we defined a database to be used so next up we have to add that. The format is the same as above and no new concepts are introduced so here is the file in full as it exists now:

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=1000
        - USER_GID=1000
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=gitea
        - DB_USER=gitea
        - DB_PASSWD=gitea
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
      ports:
        - "3000:3000"
        - "222:22"

    db:
      image: postgres:9.6

      restart: always
      environment:
        - POSTGRES_USER=gitea
        - POSTGRES_PASSWORD=gitea
        - POSTGRES_DB=gitea
      networks:
        - gitea
      volumes:
        - ./postgres:/var/lib/postgresql/data
```

However there is are a few things still missing from the above. First, the `gitea` network definition. Second, we're still storing credentials in the docker-compose file in plaintext form. Last, and less apparent, nothing guarantees that the gitea server instance will start only after the database is operational. To achieve this, we will use `depends_on`. In this case, the server should not start until the database is ready so `depends_on` will be added to the server declaration:

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=1000
        - USER_GID=1000
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=gitea
        - DB_USER=gitea
        - DB_PASSWD=gitea
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
      ports:
        - "3000:3000"
        - "222:22"
      depends_on:
        - db

    db:
      image: postgres:9.6
      restart: always
      environment:
        - POSTGRES_USER=gitea
        - POSTGRES_PASSWORD=gitea
        - POSTGRES_DB=gitea
      networks:
        - gitea
      volumes:
        - ./postgres:/var/lib/postgresql/data
```

Simple as that, we have now defined a startup dependency and ensured that our containers are started in the correct order. Let's move on to the network declaration now.

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=1000
        - USER_GID=1000
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=gitea
        - DB_USER=gitea
        - DB_PASSWD=gitea
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
      ports:
        - "3000:3000"
        - "222:22"
      depends_on:
        - db

    db:
      image: postgres:9.6
      restart: always
      environment:
        - POSTGRES_USER=gitea
        - POSTGRES_PASSWORD=gitea
        - POSTGRES_DB=gitea
      networks:
        - gitea
      volumes:
        - ./postgres:/var/lib/postgresql/data


  networks:
    gitea:
      external: false
```

So we are defining a network named `gitea` and specifying that it is not external (meaning it was not created using `docker network create gitea` but is instead managed by docker-compose). This is all that's needed to make this run, improvements will be discussed afterwards.

#### Running the application

After having written our `docker-compose.yml` or `docker-compose.yaml` (as mentioned before, both names are acceptable), we have to actually run it. I assume everyone reading installed the docker-compose command-line tool using their preferred method so we can all run `docker-compose up` or `docker-compose up -d` to start in detached mode while in the same directory as the `docker-compose.yml` file. Same as docker, it will pull the images and then bring up the containers. Pointing a web browser to `http://localhost:3000` should be enough to see gitea's front page. We're up and running!

I'll have to be a buzzkill and remind you that we're still storing access credentials inside a file that could and should be in a source code version control repository. Public git repositories are free of charge on the vast majority of code hosting websites and allow other people to reuse our docker-compose YAML files to run services more easily. It becomes clear then that our credentials should be stored elsewhere. Where could we store them though? Inside `.env` of course! Docker-compose can read environment variables if there is a file called `.env` inside the same directory that the `docker-compose.yml` file is. This means that only that single file can be excluded from version control and while we publicize everything else. Let's take a look at the `.env` file then:

```
UUID=1000
UGID=1000

DBNAME=gitea
DBUSER=gitea
DBPASSWD=gitea

PSTGRSUSR=gitea
PSTGRSPASSWD=gitea
PSTGRSDB=gitea
```

Simple as that, `variable=value` pairs is all that's needed. I avoided underscores and refactored the names a bit to make it clear when the above variables are used. Let's see how the docker-compose file will look if we want to source the values of the variables we defined

```
version: "3"

  services:

    server:
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=$UUID
        - USER_GID=$UGID
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=$DBNAME
        - DB_USER=$DBUSER
        - DB_PASSWD=$DBPASSWD
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
      ports:
        - "3000:3000"
        - "222:22"
      depends_on:
        - db

    db:
      image: postgres:9.6
      restart: always
      environment:
        - POSTGRES_USER=$PSTGRSUSR
        - POSTGRES_PASSWORD=$PSTGRSPASSWD
        - POSTGRES_DB=$PSTGRSDB
      networks:
        - gitea
      volumes:
        - ./postgres:/var/lib/postgresql/data


  networks:
    gitea:
      external: false
```

Pretty easy, right? Just like grabbing the value from variables in the shell. Now all that's required is to put `.env` in the repository's `.gitignore` so access credentials are sure to be kept safe. Not only that, it's now possible to use a different `.env` in production and a different one while developing without changing the `docker-compose.yml` at all. Feel free to play around with this and see what else you can use this trick for. For now, stop the running containers using `docker-compose down` if running in detached mode or by hitting `Ctrl-C` if you started it with `docker-compose up` and then start it again. We should notice no functional difference other than knowing our credentials are safe.

Personal preference of mine is to set the name (equivalent to `--name` in `docker run`) for the containers as well as their hostnames (equivalent to `--hostname` in `docker run`), usually to the same value. The final `docker-compose.yml` would look like this if you wanted to adopt my pet peeve:

```
version: "3"

  services:

    server:
      name: gitea-server
      container_name: gitea-server
      image: gitea/gitea
      restart:always
      environment:
        - USER_UID=$UUID
        - USER_GID=$UGID
        - DB_TYPE=postgres
        - DB_HOST=db:5432
        - DB_NAME=$DBNAME
        - DB_USER=$DBUSER
        - DB_PASSWD=$DBPASSWD
      networks:
        - gitea
      volumes:
        - ./gitea:/data
        - /etc/timezone:/etc/timezone:ro
        - /etc/localtime:/etc/localtime:ro
      ports:
        - "3000:3000"
        - "222:22"
      depends_on:
        - db

    db:
      name: gitea-db
      container_name: gitea-db
      image: postgres:9.6
      restart: always
      environment:
        - POSTGRES_USER=$PSTGRSUSR
        - POSTGRES_PASSWORD=$PSTGRSPASSWD
        - POSTGRES_DB=$PSTGRSDB
      networks:
        - gitea
      volumes:
        - ./postgres:/var/lib/postgresql/data
  networks:
    gitea:
      external: false
```

## Healthchecks

Docker is unwise as to the actual status of the container, its knowledge by default is limited to  the exit code of the command in the ENTRYPOINT or CMD declaration. Fear not though, we can definitely make it a little smarter. Enter the HEALTHCHECK statement. Its syntax is quite easy and it provides better understanding of the program's status to the container runtime. Admittedly, this is much more useful when working with kubernetes but it never hurts to know if the program is actually working or if it's hanging but hasn't fatally exited.

As on the previous part, we'll start with a simple example. Our old pal nginx will be useful once more. Also this is a great opportunity to learn a new trick. If we start the nginx image in non-detached mode, the web server's logs will be streamed to our terminal and any commands we type will have no effect since we're not in a shell. How can we override this and get a shell when we start a new container? The `docker run` command will be useful here. See, we can redefine the entrypoint and set it to be a shell. Combine that with the `-i` and `-t` arguments and we should be off to the races. After a quick `docker run --rm -it --entrypoint /bin/bash nginx` we get a shell prompt. But hold on, since we redefined the entrypoint, nginx is not actually running (you can check that by installing the `procps` package and then running `top` or the old trusty `ps aux`). Hit `Ctrl-C` to exit the interactive session (the container will be removed due to `--rm`) and let's find a different route.

First, start an nginx container in detached mode `docker run --rm -d --name ngx nginx` and then with the help of `docker exec -it ngx /bin/bash` get a shell. Ta-da! Don't forget, if you don't give it a nice name you can always use the hash-like name shown in `docker container ls`, no hindsight required. I walked you through all of this because it's going to be useful for debugging should you find yourself in a sticky situation and because we'll demonstrate a common healthcheck command. The one in question is `curl --fail http://localhost || exit 1`. This will exit with 1 (which is the error/problem code) if there is an error or `0` if there isn't. Of course we can also replace `http://localhost` with the URL of our choice. This is a common way to check if a service is still responding normally for obvious reasons, all that is required is `curl`, a very common utility and we get improved awareness of our program's status. Let's see how we can take a Dockerfile from the previous part and add a healthcheck to it. Here is the original (to be used with [this project](https://gitlab.com/insanitywholesale/reactionary "reactjs counters website")):

```
FROM node:14.1.0-alpine3.11 as build
WORKDIR /app
COPY . .
RUN npm install --global react-scripts
RUN npm install
RUN npm run build

FROM nginx:1.17.10-alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

And here it is with the healthcheck added:

```
FROM node:14.1.0-alpine3.11 as build
WORKDIR /app
COPY . .
RUN npm install --global react-scripts
RUN npm install
RUN npm run build

FROM nginx:1.17.10-alpine
COPY --from=build /app/build /usr/share/nginx/html
HEALTHCHECK CMD curl --fail http://localhost || exit 1
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Easy to read and write. It doesn't end there though. We can tweak a few knobs on it. What if it's a pretty complex Spring Boot program that takes a couple minutes to start up but after it gets there, we want to check up on it every 15 seconds and allow it 9 seconds and 5 retries to respond since it's not mission critical? This can all be tweaked. Let's take those one by one (please note: `-f` is the same as `--fail` and Spring Boot runs on port `8080` by default and exposes a health endpoint on `/health`).

In English:

2 minutes to start up, after that check every 5 seconds

In Dockerfile:

`HEALTHCHECK --start-period=120s --interval=15s --timeout=9s --retries=5 CMD curl -f http://localhost:8080/health || exit 1`

And that's it! Now it's going to run that command and change the container's health status accordingly. But what if I told you that I don't recommend using `curl` for this? Why would that be? If you read the first part, you can see that I used a pretty slim image by picking `busybox` to base the actual running image. In fact, you can replace that command with no more than 25 lines of Go. What might that look like? I'm glad you asked.

```go
package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    URL := os.Getenv("URL")
    if URL == "" {
        URL = "http://localhost"
    }

    fmt.Println("getting:", URL)
    r, err := http.Get(URL)
    if err != nil {
        os.Exit(1)
    }
    fmt.Println("status code:", r.StatusCode)
    if r.StatusCode != 200 {
        os.Exit(1)
    }

    fmt.Println("exit status 0")
    os.Exit(0)
}
```

And that's all of it, you can compile the above into a single, tiny, static binary and move into any compatible image. Not to mention that with Go's amazingly easy cross compilation ability, a quick and easy `CGO_ENABLED=0 GOOS=linux GOARCH=arm go build -v` gets you a binary to run or a Raspberry Pi for example. Play around with it if you want, I've been liking it lately and using it (mostly in images built on the `scratch` one) instead of using a bigger image that either includes `curl` or has access to it.

## LAN-only setup with reverse proxy

Time to move back to docker-compose. Traefik came to my attention when looking up reverse proxy options. To be precise, [this tutorial about traefik v1.x](https://www.smarthomebeginner.com/traefik-reverse-proxy-tutorial-for-docker/ "traefik reverse proxy tutorial for docker") which was the latest version available back then, as well as [a new guide for traefik v2.x](https://www.smarthomebeginner.com/traefik-2-docker-tutorial/ "traefik 2 docker tutorial") and I've greatly benefited from both. In my view, they're amazing for a public-facing server (that's what [my site](https://distro.watch) is using) but for LAN-only setups they're overcomplicated and overkill. Below I'll share my `docker-compose.yml` as well as traefik-related configuration. feel free to to also look at the raw files in

[the repository](https://gitlab.com/insanitywholesale/docks-and-whales/-/blob/master/code/2dock2furious/ "code for this tutorial")

for more help. Specifically, for how to run nextcloud without https which took me a good 20 minutes of searching to find the relevant documentation (always love multiple major version old docs linked from a forum post made at least half a decade ago). However, let's back up just a bit, one thing at a time.

### Reverse Proxies

What are they and what do they do? A proxy is essentially a middleman, in the context of internet traffic, it usually means that it's taking the traffic you send it and forwarding it somewhere. Flipping this concept, a reverse proxy takes the traffic sent to it and decides where in the servers behind it to send it. So, normal proxy is a middle man for all its clients to reach any server while a reverse proxy is a middle man for all its servers to be reached by a client. Too theoretical? Here is an example then, say my gitea instance is running on my laptop and my blog is running on my desktop. When someone visits git.inherently.xyz they should be redirected to my laptop and if they visit blog.inherently.xyz they should be redirected to my desktop. It would be possible to open the required ports on both computers and keep opening ports for each new thing I decide to run but it gets out of hand quickly. Here is where a reverse proxy comes in to solve the problem. I can run hundreds of applications or services and only open 1 port, the reverse proxy's port. The most used reverse proxies are nginx, haproxy and traefik (maybe caddy too). Initially I chose traefik because it was created for a container-focused workload and the excellent tutorial for traefik v1.x that I linked above existed. Now that this is covered, let's move on to the actual setup.

### Writing the docker-compose.yml

First up, make a directory (I recommend `$HOME/docker`) to put all the relevant files in (this will be known as `DOCKDIR` for our purposes). Since the basics have been explained, here is where we are going to start from:  
create a `docker-compose.yml` inside the `DOCKDIR` with the following content

```
version: "3"

services:

  traefik:
    image: traefik:1.7-alpine
    container_name: traefik
    hostname: traefik
    restart: always
    networks:
      - default
      - traefik_proxy
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${DOCKDIR}/traefik:/etc/traefik


networks:
  traefik_proxy:
    external:
      name: traefik_proxy
  default:
    driver: bridge
```

You didn't read this wrong, I'm using the latest release of the v1.x of traefik since the configuration is much simpler. This isn't fully ready but we're taking it one step at a time. So, remember what external means? We have to run `docker network create traefik_proxy` before ever running `docker-compose up` since it will fail due to the network missing. As for a brief explanation, traefik's api is running on port 8080 so we expose that and port 80 is where all HTTP traffic will go to. We also bind mount the configuration directory so we can edit traefik's config easily. Save and exit the file and create a subdirectory named `traefik` under the `DOCKDIR` to put the `traefik.toml` in. Said file will include the following:

```
#options for loglevel are: DEBUG, INFO, WARN, ERROR, FATAL, PANIC
logLevel = "DEBUG"

#turns off traefik's checking of certs
#since we use none, it's fine
InsecureSkipVerify = true

defaultEntryPoints = ["http"]

[entryPoints]
  [entryPoints.http]
  address = ":80"

[api]
  entryPoint = "traefik"
  dashboard = true
  address = ":8080"

[docker]
endpoint = "unix:///var/run/docker.sock"
domain = "docks.localhome"
watch = true
#we're on LAN only and it avoids a label
exposedbydefault = true
```

First, enabling debug mode to be able to get logs in case something is wrong and turning off certificate checking since it will all be http-only. We set `http` as the only default entrypoint and then define it addresses on port 80. After that, we enable the api with the dashboard and make it accessible on port 8080. Finally, we add docker-related settings and set all services to be exposed by default without requiring the use of a label for the container. Labels? Let's go back to the `docker-compose.yml` and add a couple things. Traefik uses labels for configuring apects of how the reverse proxy will treat an application. For example:

```
version: "3"

services:

  traefik:
    image: traefik:1.7-alpine
    container_name: traefik
    hostname: traefik
    restart: always
    networks:
      - default
      - traefik_proxy
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${DOCKDIR}/traefik:/etc/traefik
    labels:
      - "traefik.backend=traefik"
      - "traefik.frontend.rule=Host:traefik.$DOMAINNAME"
      - "traefik.port=8080"
      - "traefik.protocol=http"

networks:
  traefik_proxy:
    external:
      name: traefik_proxy
  default:
    driver: bridge
```

This sets the name for the backend that handles its traffic to `traefik`, makes it accessible by using `traefik.$DOMAINNAME` (we'll define this in our `.env`), sets the port that the application runs on as `8080` and defines the protocol as http. This little bit will be added to almost every container with some modifications if it's a container that should accept traffic from clients and not a database or something else meant for internal use only. I'll use a container running caddy and one using nginx to demonstrate:

```
version: "3"

services:

  caddy:
    image: caddy
    restart: always
    networks:
      - traefik_proxy
    labels:
      - "traefik.backend=caddy"
      - "traefik.frontend.rule=Host:web1.$DOMAINNAME"
      - "traefik.port=80"
      - "traefik.protocol=http"

  nginx:
    image: nginx
    restart: always
    networks:
      - traefik_proxy
    labels:
      - "traefik.backend=nginx"
      - "traefik.frontend.rule=Host:web2.$DOMAINNAME"
      - "traefik.port=80"
      - "traefik.protocol=http"

  traefik:
    image: traefik:1.7-alpine
    restart: always
    networks:
      - default
      - traefik_proxy
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${DOCKDIR}/traefik:/etc/traefik
    labels:
      - "traefik.backend=traefik"
      - "traefik.frontend.rule=Host:traefik.$DOMAINNAME"
      - "traefik.port=8080"
      - "traefik.protocol=http"

networks:
  traefik_proxy:
    external:
      name: traefik_proxy
  default:
    driver: bridge
```

Fairly simple, right? Only one thing is missing at the moment and that is our `.env` to define a few commonly used variables. Here it is then:

```
PUID=1000
PGID=998
TZ="Europe/Athens"
DOCKDIR=/home/user/docker
DOMAINNAME=docks.localhome
MYSQL_ROOT_PASSWORD="Th1s1s_A_verySecurePassword_123"
```

I defined some commonly used things like a password for databases, timezone, the domain name along with the user and group docker runs as. The last two can be discovered by running `id` and checking the output. But wait, `localhome` is not the current local domain and there is no host called `docks` on this non-existent local domain. Sounds weird but this is not a problem, it will be solved through the DNS server (explained later on in the guide) but for now you can put the IP of the computer and put it in `/etc/hosts` like below

if it is remote:

```
192.168.35.18	web1.docks.localhome
192.168.35.18	web2.docks.localhome
192.168.35.18	traefik.docks.localhome
```

or if you're running it on the same host you're accessing it from:

```
127.0.1.1	web1.docks.localhome
127.0.1.1	web2.docks.localhome
127.0.1.1	traefik.docks.localhome
```

We need this because traefik responds based on the name that is requested. Time to run `docker-compose up -d` finally and then visit `web1.docks.localhome` then`web2.docks.localhome` followed up by`traefik.docks.localhome` to check if the setup was successful. Hopefully you see the correct page for each one (web1 is caddy, web2 is nginx and traefik is traefik as expected).

## Logs

The above is all fine and dandy but what if things go wrong? A common first action is to look at the logs. Since everything is running inside docker, we could start an interactive terminal and check there but anything that has already been printed will not be shown. Here is where the `logs` subcommand comes in. While in the same directory as the `docker-compose.yml` (or by using the `-f` flag) we can see the logs from all the containers that were launched, including the previous 50 lines, like so:

```
docker-compose -f docker-compose.yml logs --tail=50 -f
```

I included the file flag for docker-compose and the follow flag for `logs` to showcase how they should be positioned since order is important here. This command will print the last 50 lines of logs from all containers that were started from the specified `docker-compose.yml` and keep following the logs as they're printed. That's not what we want to always do because the problematic container might be a single one and the clutter from the rest is distracting. No problem, simply append the specific one that needs to be examined, let's use traefik as the example:

```
docker-compose -f docker-compose.yml logs --tail=50 -f traefik
```

And that's about it for logs, unlike conventional systems there is not much "unicorn" configuration or at least it should be avoided as much as possible. Keeping the setup easy to replicate is a good thing, the container might restart due to failure and that should be no problem for our operations.

[//]: # (maybe add traefik 2 example as well but I haven't figured it out yet)

[//]: # (add public+private setup based on https://github.com/ShoGinn/homelab/wiki/How-to-setup-traefik-for-a-closed-network-and-external)

## Backups

If there are not at least 2 copies of a file, it might as well not exist. Backups are very important yet often neglected. In this case there is no reason for that to be the case. With the above setup in mind, every piece of data required to replicate the setup is under one directory so all we need is to keep a copy of that on a different hard drive. Using a compressed tarball with preserved permissions or rsync, again preserving the permissions, should be enough for a home setup with a single node. Multi-node setups are not going to be covered here since that would land us in kubernetes territory which is vast enough to warrant its own writeup.

What would a simple backup such as the one I suggest above look like then?

The following commands are examples that you should tweak depending on your setup and not meant to be copy-pasted and used
```
rsync -Pauvr --progress /home/user/docker /mnt/externaldrive/docker-bak-$(date +'%F')
```
and
```
tar czvf /mnt/externaldrive/docker-bak-$(date +'%F') /home/user/docker
```

[//]: # (portainer for gui, watchtower for updates)

## Registry

Connecting to dockerhub as well as having an account there can bothersome to impossible in air-gapped setups and having to go to the internet every time you want an image is annoying. Good news, we can run our own registry and cache public images as well as push our own images there. This will require a tiny amount of setup on the clients but nothing that will take more than a few seconds.

### Local image storage

First let's see how we can run a local docker registry using a raw docker command:

```
docker run -d -p 5000:5000 -v ./registry:/var/lib/registry registry:2
```

With the above setup, we'll have a persistent registry running on port 5000 of the host that is running it. For the client setup I'm going to assume everything is on the same system so I will use `localhost` for the registry address but in reality you'll be running it on a remote host so feel free to replace `localhost` with the IP or hostname of the host that the registry is running on in the following examples. On the client's side create the file `/etc/docker/daemon.json` (it doesn't exist by default) and insert the following into it:
```
{
	"insecure-registries" : [
		"localhost:5000"
	]
}
```

Don't worry about the "insecure" part, that's because it's not using https. In order to test this out, try pushing an image to it and then pulling it:

```
docker pull nginx:1.19.2-alpine
docker tag nginx:1.19.2-alpine localhost:5000/ngxalp
docker push localhost:5000/ngxalp
docker image remove nginx:1.19.2-alpine
docker image remove localhost:5000/ngxalp
docker pull localhost:5000/ngxalp
```

And there we have it, our very own local dockerhub. That's not where the story ends though. I promised we could also cache images and that's what we're going to get into next.

### Pull-through cache

This one requires a tiny bit more configuration but still nothing extravagant. Start by editing `/etc/docker/registry/config.yml` (the registry subdirectory as well as the config.yml file don't exist by default so you'll have to create them first) and inserting the following in it:

```
proxy:
  remoteurl: https://registry-1.docker.io
```

and afterwards add an extra option in `/etc/docker/daemon.json` so the file looks like the one below:

```
{
	"insecure-registries" : [
		"localhost:5000"
	],
	"registry-mirrors": [
		"http://localhost:5000"
	]
}
```


[//]: # (k3s but with docker to use the registry -- k8s w/ kubeadm makes master not work)

[//]: # (mern_first (update images too) -- 2 ports, one port for main one port for websocket)

[//]: # (hashes in FROM statements for extra security)
