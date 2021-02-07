# no official hugo image so this is necessary
FROM golang:latest as build
ENV CGO_ENABLED 0
WORKDIR /go/src
RUN git clone https://github.com/gohugoio/hugo.git
WORKDIR /go/src/hugo
RUN go install -v
WORKDIR /go/src
RUN git clone https://gitlab.com/insanitywholesale/inheresite-hugo
WORKDIR /go/src/inheresite-hugo
RUN hugo

# good old alpine to serve the files
FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/
COPY --from=build /go/src/inheresite-hugo/public /usr/share/nginx/html
