# no official hugo image so this is necessary
FROM golang:1.17 as buildsite
ENV CGO_ENABLED 0
WORKDIR /go/src
RUN git clone https://github.com/gohugoio/hugo.git
WORKDIR /go/src/hugo
RUN go install -v
WORKDIR /go/src/inheresite-hugo
COPY . .
RUN hugo

# good old nginx to serve the files
FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/
COPY --from=buildsite /go/src/inheresite-hugo/public /usr/share/nginx/html
