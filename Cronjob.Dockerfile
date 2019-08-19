FROM alpine:latest

LABEL maintainer="https://allaboutaws.com"
ARG DEBIAN_FRONTEND=noninteractive

USER root

RUN apk add --update --no-cache \
    jq \
    py-pip \
    bc \
    coreutils \
    bash

# update pip
RUN pip install --upgrade pip

RUN pip install awscli --upgrade

# Configure cron
COPY ./crontab /etc/cron/crontab

# Init cron
RUN crontab /etc/cron/crontab

WORKDIR /code/
COPY ./scaling.sh /code/
COPY ./publish-Backlog-per-Worker.sh /code

COPY ./entrypoint.sh /etc/app/entrypoint
RUN chmod +x /etc/app/entrypoint
ENTRYPOINT /bin/sh /etc/app/entrypoint

EXPOSE 8080