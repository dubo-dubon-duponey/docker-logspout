##########################
# Building image
##########################
FROM        --platform=$BUILDPLATFORM golang:1.13-rc-buster                                               AS builder

MAINTAINER  dubo-dubon-duponey@jsboot.space
# Install dependencies and tools
ARG         DEBIAN_FRONTEND="noninteractive"
ENV         TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
RUN         apt-get update                                                                                > /dev/null
RUN         apt-get install -y git                                                                        > /dev/null
WORKDIR     /build

# Versions: v3.2.6
ARG         LOGSPOUT_VERSION=591787f3d3202cbe029a9cff6c14e3a178e1f78c
ARG         TARGETPLATFORM

# Checkout logspout upstream, install glide and run it
WORKDIR     /go/src/github.com/gliderlabs/logspout
RUN         git clone https://github.com/gliderlabs/logspout.git .
RUN         git checkout $LOGSPOUT_VERSION
RUN         go get github.com/Masterminds/glide
RUN         $GOPATH/bin/glide install

# Add the logdna stuff
COPY        modules.go .
COPY        logdna ./vendor/github.com/logdna/logspout/logdna

# Build it
RUN         arch=${TARGETPLATFORM#*/} && \
            env GOOS=linux GOARCH=${arch%/*} go build -ldflags "-X main.Version=$(cat VERSION)-custom" -o /bin/logspout

#######################
# Running image
#######################
FROM        debian:buster-slim

MAINTAINER  dubo-dubon-duponey@jsboot.space
ARG         DEBIAN_FRONTEND="noninteractive"
ENV         TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
RUN         apt-get update              > /dev/null && \
            apt-get dist-upgrade -y                 && \
            apt-get -y autoremove       > /dev/null && \
            apt-get -y clean            && \
            rm -rf /var/lib/apt/lists/* && \
            rm -rf /tmp/*               && \
            rm -rf /var/tmp/*

COPY        --from=builder /bin/logspout /bin/logspout

EXPOSE      80
VOLUME      /mnt/routes

ENTRYPOINT  ["/bin/logspout"]
