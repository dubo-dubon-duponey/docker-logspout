##########################
# Building image
##########################
FROM        --platform=$BUILDPLATFORM golang:1.13-rc-buster                                               AS builder

# Install dependencies and tools
ARG         DEBIAN_FRONTEND="noninteractive"
ENV         TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
RUN         apt-get update                                                                                > /dev/null
RUN         apt-get install -y --no-install-recommends git=1:2.20.1-2                                     > /dev/null
WORKDIR     /build

# Versions: v3.2.6
ARG         LOGSPOUT_VERSION=591787f3d3202cbe029a9cff6c14e3a178e1f78c
ARG         GLIDE_VERSION=8ed5b9292379d86c39592a7e6a58eb9c903877cf
ARG         TARGETPLATFORM

# Checkout logspout upstream, install glide and run it
WORKDIR     /go/src/github.com/gliderlabs/logspout
RUN         git clone https://github.com/gliderlabs/logspout.git .
RUN         git checkout $LOGSPOUT_VERSION

# Install glide
RUN         mkdir -p "$GOPATH"/src/github.com/Masterminds
RUN         git -C "$GOPATH"/src/github.com/Masterminds clone git://github.com/Masterminds/glide
RUN         git -C "$GOPATH"/src/github.com/Masterminds/glide checkout "$GLIDE_VERSION"
RUN         go install "$GOPATH"/src/github.com/Masterminds/glide
RUN         "$GOPATH"/bin/glide install

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

LABEL       dockerfile.copyright="Dubo Dubon Duponey <dubo-dubon-duponey@jsboot.space>"

ARG         DEBIAN_FRONTEND="noninteractive"
ENV         TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
RUN         apt-get update              > /dev/null && \
            apt-get -y autoremove       > /dev/null && \
            apt-get -y clean            && \
            rm -rf /var/lib/apt/lists/* && \
            rm -rf /tmp/*               && \
            rm -rf /var/tmp/*

COPY        --from=builder /bin/logspout /bin/logspout

EXPOSE      80
VOLUME      /mnt/routes

ENTRYPOINT  ["/bin/logspout"]
