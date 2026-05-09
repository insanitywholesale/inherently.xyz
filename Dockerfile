# no official hugo image so this is necessary
FROM ubuntu:26.04 AS buildsite
RUN apt update && apt -y full-upgrade && apt -y install hugo
WORKDIR /inheresite-hugo
COPY . .
RUN hugo

# good old nginx to serve the files
FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/
COPY --from=buildsite /inheresite-hugo/public /usr/share/nginx/html
