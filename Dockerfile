# no official hugo image so this is necessary
FROM golang:1.16 as buildsite
ENV CGO_ENABLED 0
WORKDIR /go/src
RUN git clone https://github.com/gohugoio/hugo.git
WORKDIR /go/src/hugo
RUN go install -v
WORKDIR /go/src/inheresite-hugo
COPY . .
RUN hugo

# build the files into a server binary
#FROM golang:1.16 as buildwebsrv
#ENV CGO_ENABLED 0
#WORKDIR /go/src
#RUN git clone https://github.com/insanitywholesale/basegowebserver
#WORKDIR /go/src/basegowebserver
#COPY --from=buildsite /go/src/inheresite-hugo/public ./public
#RUN go install -v
#
# run the binary in a very minimal environment
#FROM scratch as run
#COPY --from=buildwebsrv /go/bin/basegowebserver /hugosite
#EXPOSE 11789
#ENTRYPOINT ["/hugosite"]

# good old nginx to serve the files
FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/
COPY --from=buildsite /go/src/inheresite-hugo/public /usr/share/nginx/html
