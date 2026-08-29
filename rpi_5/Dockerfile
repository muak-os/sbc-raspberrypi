# syntax = docker/dockerfile-upstream:1.26.0-labs
# rpi_5 (Pi 5 / CM5, BCM2712) overlay for muak.

ARG UBOOT_IMAGE=sbc-raspberrypi/u-boot:latest
ARG FIRMWARE_IMAGE=sbc-raspberrypi/firmware:latest

FROM scratch AS prep

ARG UBOOT_IMAGE
ARG FIRMWARE_IMAGE

COPY --from=${UBOOT_IMAGE} /u-boot.bin /esp/u-boot.bin
COPY --from=${FIRMWARE_IMAGE} /boot/bcm2712*.dtb /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/overlays /esp/overlays
COPY --from=${FIRMWARE_IMAGE} /boot/COPYING.linux /esp/

FROM scratch

ARG ESP_GUID=C12A7328-F81F-11D2-BA4B-00A0C93EC93B

COPY --from=prep /esp "/rpi_5/partitions/${ESP_GUID}/"
COPY config.txt "/rpi_5/partitions/${ESP_GUID}/config.txt"

LABEL org.opencontainers.image.title="muak-sbc-raspberrypi"
LABEL org.opencontainers.image.description="Raspberry Pi 5 boot overlay for Muak"
LABEL org.opencontainers.image.source="https://github.com/muak-os/sbc-raspberrypi"
