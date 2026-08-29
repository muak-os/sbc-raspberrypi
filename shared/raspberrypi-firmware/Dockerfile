# syntax = docker/dockerfile-upstream:1.26.0-labs
# Raspberry Pi GPU firmware boot files.

ARG FIRMWARE_VERSION=1.20260521
ARG FIRMWARE_SHA256=b900de58571920a306ab2d1296500499d0744451dbefda0c76b79e652bb71cb7

FROM --platform=$BUILDPLATFORM docker.io/alpine:3.24 AS build

ARG FIRMWARE_VERSION
ARG FIRMWARE_SHA256

RUN apk add --no-cache wget ca-certificates

RUN wget -q \
  "https://github.com/raspberrypi/firmware/archive/refs/tags/${FIRMWARE_VERSION}.tar.gz" \
  -O firmware.tar.gz \
  && echo "${FIRMWARE_SHA256}  firmware.tar.gz" | sha256sum -c - \
  && tar xzf firmware.tar.gz --strip-components=1 \
  && rm firmware.tar.gz

FROM scratch

COPY --from=build /boot /boot

LABEL org.opencontainers.image.title="muak-raspberrypi-firmware"
LABEL org.opencontainers.image.description="Raspberry Pi GPU firmware boot files for Muak overlays"
LABEL org.opencontainers.image.source="https://github.com/muak-os/sbc-raspberrypi"
