# syntax = docker/dockerfile-upstream:1.26.0-labs
# rpi_generic (Pi 4 / 400 / CM4, BCM2711) overlay for muak.

ARG UBOOT_IMAGE=sbc-raspberrypi/u-boot:latest
ARG FIRMWARE_IMAGE=sbc-raspberrypi/firmware:latest

FROM scratch AS prep

ARG UBOOT_IMAGE
ARG FIRMWARE_IMAGE

COPY --from=${UBOOT_IMAGE} /u-boot.bin /esp/u-boot.bin
COPY --from=${FIRMWARE_IMAGE} /boot/*.elf /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/*.dat /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/bootcode.bin /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/COPYING.linux /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/LICENCE.broadcom /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/bcm2708*.dtb /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/bcm2709*.dtb /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/bcm2710*.dtb /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/bcm2711*.dtb /esp/
COPY --from=${FIRMWARE_IMAGE} /boot/overlays /esp/overlays

FROM scratch

ARG ESP_GUID=C12A7328-F81F-11D2-BA4B-00A0C93EC93B

COPY --from=prep /esp "/rpi_generic/partitions/${ESP_GUID}/"
COPY config.txt "/rpi_generic/partitions/${ESP_GUID}/config.txt"

LABEL org.opencontainers.image.title="muak-sbc-raspberrypi"
LABEL org.opencontainers.image.description="Raspberry Pi generic boot overlay for Muak"
LABEL org.opencontainers.image.source="https://github.com/muak-os/sbc-raspberrypi"
