# Patched immich-upload-optimizer v0.5.3: disable redirect wait page.
# Immich web UI does not poll /_immich-upload-optimizer/wait; parallel uploads then fail with unexpected EOF.
# Base image keeps Caesium/ImageMagick/HandBrake; only the Go binary is replaced.
FROM golang:1.23-bookworm AS build
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch v0.5.3 https://github.com/miguelangel-nubla/immich-upload-optimizer.git .
# v0.5.3 defaults clientFollowsRedirects=true (wait page); Immich web UI never polls it.
RUN sed -i 's/clientFollowsRedirects := true/clientFollowsRedirects := false/' jobs.go
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o immich-upload-optimizer .

FROM ghcr.io/miguelangel-nubla/immich-upload-optimizer:v0.5.3
# Base image runs /usr/local/bin/immich-upload-optimizer (not /immich-upload-optimizer).
COPY --from=build /src/immich-upload-optimizer /usr/local/bin/immich-upload-optimizer
