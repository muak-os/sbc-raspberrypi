# syntax = docker/dockerfile-upstream:1.26.0-labs
# U-Boot for Raspberry Pi (rpi_arm64_defconfig).

ARG UBOOT_VERSION=2026.01
ARG UBOOT_SHA256=b60d5865cefdbc75da8da4156c56c458e00de75a49b80c1a2e58a96e30ad0d54

FROM --platform=$BUILDPLATFORM docker.io/debian:bookworm-slim AS build

ARG UBOOT_VERSION
ARG UBOOT_SHA256

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  bc \
  bison \
  build-essential \
  ca-certificates \
  device-tree-compiler \
  flex \
  gcc-aarch64-linux-gnu \
  libc6-dev-arm64-cross \
  libgnutls28-dev \
  libssl-dev \
  make \
  pkg-config \
  python3 \
  python3-dev \
  swig \
  wget \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN wget -q "https://ftp.denx.de/pub/u-boot/u-boot-${UBOOT_VERSION}.tar.bz2" \
  && echo "${UBOOT_SHA256}  u-boot-${UBOOT_VERSION}.tar.bz2" | sha256sum -c - \
  && tar xjf "u-boot-${UBOOT_VERSION}.tar.bz2" --strip-components=1 \
  && rm "u-boot-${UBOOT_VERSION}.tar.bz2"

RUN make rpi_arm64_defconfig

RUN make -j"$(nproc)" CROSS_COMPILE=aarch64-linux-gnu- HOSTLDLIBS_mkimage="-lssl -lcrypto"

FROM scratch AS export

COPY --from=build /src/u-boot.bin /u-boot.bin

LABEL org.opencontainers.image.title="muak-u-boot-raspberrypi"
LABEL org.opencontainers.image.description="U-Boot (rpi_arm64_defconfig) for Muak Raspberry Pi overlays"
LABEL org.opencontainers.image.source="https://github.com/muak-os/sbc-raspberrypi"
