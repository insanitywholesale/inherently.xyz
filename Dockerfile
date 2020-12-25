FROM golang:latest as build
ENV CGO_ENABLED 0
ENV GOPROXY http://oldboi.hell,direct
WORKDIR /go/src
RUN git clone https://github.com/gohugoio/hugo.git
WORKDIR /go/src/hugo
RUN rm go.*
RUN go mod init
RUN go get -v
RUN go install -v
WORKDIR /go/src
RUN git clone https://gitlab.com/insanitywholesale/inheresite-hugo
WORKDIR /go/src/inheresite-hugo
RUN git checkout feature-advancing
RUN hugo

#FROM jojomi/hugo
#WORKDIR /src
#COPY . .
